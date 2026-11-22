// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.android;

import android.app.Activity;
import android.app.Application;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceError;
import org.json.JSONObject;

/** Local JS preflight on the UI thread. Does not fetch ads or grant rewards. */
public class WebViewWarmup {
    public interface Callback { void complete(String result); }
    private final Handler handler=new Handler(Looper.getMainLooper());
    private WebView view;
    private boolean finished;
    private boolean evaluating;
    private Callback callback;
    private String provider="unknown";
    private String profile="existing";
    private final Runnable timeout=()->finish(false,"WebView did not execute local JavaScript within 15 seconds");

    public static String processProfile(String name){
        return "neon_"+name.replaceAll("[^A-Za-z0-9_.-]","_");
    }
    protected WebView createView(Activity activity){return new WebView(activity);}
    public void begin(Activity activity,Callback result){
        if(Looper.myLooper()!=Looper.getMainLooper()){
            handler.post(()->begin(activity,result));return;
        }
        callback=result;
        if(activity==null || activity.isFinishing()){finish(false,"Android activity is unavailable");return;}
        handler.postDelayed(timeout,15000);
        try{
            // A separate profile prevents WebView directory conflicts between app processes.
            // If a provider was already initialized, continue with its existing profile.
            if(Build.VERSION.SDK_INT>=28){
                String process=Application.getProcessName();
                if(process==null)process=activity.getPackageName();
                try{profile=processProfile(process);WebView.setDataDirectorySuffix(profile);}
                catch(IllegalStateException alreadyStarted){profile="already initialized";}
            }
            if(Build.VERSION.SDK_INT>=26){
                try{
                    PackageInfo info=WebView.getCurrentWebViewPackage();
                    if(info!=null)provider=info.packageName+" / "+info.versionName;
                }catch(Throwable unavailable){provider="metadata unavailable";}
            }
            view=createView(activity);
            view.setAlpha(0f);
            view.setFocusable(false);
            view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
            view.getSettings().setJavaScriptEnabled(true);
            view.getSettings().setBlockNetworkLoads(true);
            view.getSettings().setAllowFileAccess(false);
            view.getSettings().setAllowContentAccess(false);
            View decor=activity.getWindow().getDecorView();
            if(decor instanceof ViewGroup)((ViewGroup)decor).addView(view,new ViewGroup.LayoutParams(1,1));
            view.setWebViewClient(new WebViewClient(){
                @Override public void onPageFinished(WebView web,String url){
                    if(finished || evaluating)return;
                    evaluating=true;
                    web.evaluateJavascript("6 * 7",value->finish("42".equals(value),"42".equals(value)?"Local JavaScript OK (6×7=42)":"Unexpected JavaScript result: "+value));
                }
                @Override public void onReceivedError(WebView web,WebResourceRequest request,WebResourceError error){
                    if(request.isForMainFrame())finish(false,"WebView "+error.getErrorCode()+": "+error.getDescription());
                }
            });
            view.loadData("<!doctype html><html><body></body></html>","text/html","UTF-8");
        }catch(Throwable error){
            finish(false,error.getClass().getSimpleName()+": "+String.valueOf(error.getMessage()));
        }
    }
    public void cancel(){
        if(Looper.myLooper()!=Looper.getMainLooper()){handler.post(this::cancel);return;}
        finished=true;handler.removeCallbacks(timeout);cleanup();callback=null;
    }
    private void cleanup(){
        if(view==null)return;
        try{
            if(view.getParent() instanceof ViewGroup)((ViewGroup)view.getParent()).removeView(view);
            view.stopLoading();view.destroy();
        }catch(Throwable ignored){}
        view=null;
        // Never call pauseTimers(): it would also pause the SDK's WebViews.
    }
    private void finish(boolean ok,String message){
        if(finished)return;
        finished=true;handler.removeCallbacks(timeout);
        cleanup();
        JSONObject result=new JSONObject();
        try{result.put("ok",ok);result.put("message",message);result.put("provider",provider);result.put("profile",profile);}catch(Exception ignored){}
        Callback deliver=callback;callback=null;
        if(deliver!=null)deliver.complete(result.toString());
    }
}
