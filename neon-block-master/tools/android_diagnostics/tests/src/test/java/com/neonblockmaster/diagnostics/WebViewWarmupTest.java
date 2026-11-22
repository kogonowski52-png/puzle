package com.neonblockmaster.diagnostics;
import com.neonblockmaster.android.WebViewWarmup;
import android.app.Activity;
import android.os.Looper;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.ValueCallback;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.json.JSONObject;
import java.util.concurrent.TimeUnit;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class) @Config(sdk=30)
public class WebViewWarmupTest {
    static class ProbeWebView extends WebView {
        WebViewClient client;
        boolean evaluatedOnUi;
        boolean destroyed;
        boolean completes=true;
        ProbeWebView(Activity a){super(a);}
        @Override public void setWebViewClient(WebViewClient value){super.setWebViewClient(value);client=value;}
        @Override public void loadData(String data,String mime,String encoding){if(completes)client.onPageFinished(this,"data:text/html");}
        @Override public void evaluateJavascript(String script,ValueCallback<String> callback){
            assertEquals("6 * 7",script);evaluatedOnUi=Looper.myLooper()==Looper.getMainLooper();callback.onReceiveValue("42");
        }
        @Override public void destroy(){destroyed=true;super.destroy();}
    }
    @Test public void localJavascriptRunsOnUiWithoutNetworkAndViewIsReleased()throws Exception{
        Activity activity=Robolectric.buildActivity(Activity.class).setup().get();
        ProbeWebView web=new ProbeWebView(activity);
        int children=((ViewGroup)activity.getWindow().getDecorView()).getChildCount();
        WebViewWarmup warmup=new WebViewWarmup(){@Override protected WebView createView(Activity a){return web;}};
        String[] result={null};warmup.begin(activity,value->result[0]=value);
        JSONObject report=new JSONObject(result[0]);
        assertTrue(report.getBoolean("ok"));assertTrue(web.evaluatedOnUi);
        assertTrue(web.getSettings().getBlockNetworkLoads());
        assertFalse(web.getSettings().getAllowFileAccess());
        assertTrue(web.destroyed);
        assertEquals(children,((ViewGroup)activity.getWindow().getDecorView()).getChildCount());
    }
    @Test public void providerFailureReturnsActualExceptionWithoutClaimingReady()throws Exception{
        Activity activity=Robolectric.buildActivity(Activity.class).setup().get();
        WebViewWarmup warmup=new WebViewWarmup(){@Override protected WebView createView(Activity a){throw new IllegalStateException("provider-test-failure");}};
        String[] result={null};warmup.begin(activity,value->result[0]=value);
        JSONObject report=new JSONObject(result[0]);assertFalse(report.getBoolean("ok"));assertTrue(report.getString("message").contains("provider-test-failure"));
    }
    @Test public void timeoutReleasesViewAndCompletesOnlyOnce()throws Exception{
        Activity activity=Robolectric.buildActivity(Activity.class).setup().get();
        ProbeWebView web=new ProbeWebView(activity);web.completes=false;
        WebViewWarmup warmup=new WebViewWarmup(){@Override protected WebView createView(Activity a){return web;}};
        int[] calls={0};String[] result={null};warmup.begin(activity,value->{calls[0]++;result[0]=value;});
        shadowOf(Looper.getMainLooper()).idleFor(16,TimeUnit.SECONDS);
        assertFalse(new JSONObject(result[0]).getBoolean("ok"));assertEquals(1,calls[0]);assertTrue(web.destroyed);
        warmup.cancel();assertEquals(1,calls[0]);
    }
    @Test public void appProcessesUseDifferentSafeProfiles(){
        assertNotEquals(WebViewWarmup.processProfile("com.neon.game"),WebViewWarmup.processProfile("com.neon.game:diagnostics"));
        assertFalse(WebViewWarmup.processProfile("com.neon/game:process").contains("/"));
    }
}
