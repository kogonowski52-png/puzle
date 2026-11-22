package com.neonblockmaster.diagnostics;
import android.app.Activity;
import android.content.Context;
import android.content.ClipboardManager;
import android.content.pm.ProviderInfo;
import android.net.Uri;
import android.widget.Button;
import android.view.View;
import android.view.ViewGroup;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.nio.charset.StandardCharsets;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class) @Config(sdk=30)
public class StartupTest {
    private Button button(View view,String text){
        if(view instanceof Button && text.contentEquals(((Button)view).getText()))return (Button)view;
        if(view instanceof ViewGroup)for(int i=0;i<((ViewGroup)view).getChildCount();i++){
            Button found=button(((ViewGroup)view).getChildAt(i),text);if(found!=null)return found;
        }
        return null;
    }
    @Test public void noCrashStartsGameWithoutAReportScreen(){
        StartupActivity activity=Robolectric.buildActivity(StartupActivity.class).setup().get();
        assertEquals("com.godot.game.GodotApp",shadowOf(activity).getNextStartedActivity().getComponent().getClassName());
        assertTrue(activity.isFinishing());
    }
    @Test public void javaCrashIsVisibleAndCanBeCopied()throws Exception{
        File crash=new File(RuntimeEnvironment.getApplication().getFilesDir(),"neon-java-crash.txt");
        try(FileOutputStream out=new FileOutputStream(crash)){out.write("IllegalStateException: startup contract failed".getBytes(StandardCharsets.UTF_8));}
        StartupActivity activity=Robolectric.buildActivity(StartupActivity.class).setup().get();
        assertFalse(activity.isFinishing());
        Button copy=button(activity.getWindow().getDecorView(),"Kopiuj raport");assertNotNull(copy);copy.performClick();
        String text=((ClipboardManager)activity.getSystemService(Context.CLIPBOARD_SERVICE)).getPrimaryClip().getItemAt(0).getText().toString();
        assertTrue(text.contains("startup contract failed"));
        assertNotNull(button(activity.getWindow().getDecorView(),"Udostępnij plik raportu"));
    }
    @Test public void uncaughtJavaFailureIsSavedAndDelegatesToAndroid()throws Exception{
        Thread.UncaughtExceptionHandler original=Thread.getDefaultUncaughtExceptionHandler();
        final boolean[] delegated={false};
        Thread.setDefaultUncaughtExceptionHandler((thread,error)->delegated[0]=true);
        try{
            CrashApplication application=new CrashApplication();
            application.attachBaseContext(RuntimeEnvironment.getApplication());
            Thread.getDefaultUncaughtExceptionHandler().uncaughtException(Thread.currentThread(),new IllegalStateException("native-startup-test-marker"));
            File stored=new File(application.getFilesDir(),"neon-java-crash.txt");
            assertTrue(stored.isFile());
            assertTrue(new String(java.nio.file.Files.readAllBytes(stored.toPath()),StandardCharsets.UTF_8).contains("native-startup-test-marker"));
            assertTrue(delegated[0]);
        }finally{Thread.setDefaultUncaughtExceptionHandler(original);}
    }
    @Test public void providerRejectsUnknownFilesAndWriting()throws Exception{
        ReportProvider provider=new ReportProvider();ProviderInfo info=new ProviderInfo();info.authority="test.diagnostics";
        provider.attachInfo(RuntimeEnvironment.getApplication(),info);
        for(String uri:new String[]{"content://test.diagnostics/../secret","content://test.diagnostics/unknown"}){
            try{provider.openFile(Uri.parse(uri),"r");fail("arbitrary file access");}catch(FileNotFoundException expected){}
        }
        try{provider.openFile(Uri.parse("content://test.diagnostics/neon-report.txt"),"w");fail("writing allowed");}catch(FileNotFoundException expected){}
    }
}
