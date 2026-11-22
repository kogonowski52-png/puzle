// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.android;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.HashSet;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.Set;

/** Godot bridge for an actual system WebView/JS check, no simulated ad delivery. */
public final class NeonWebView extends GodotPlugin {
    private WebViewWarmup warmup;
    private final AtomicBoolean collecting=new AtomicBoolean();
    public NeonWebView(Godot godot){super(godot);}
    @Override public String getPluginName(){return "NeonWebView";}
    @Override public Set<SignalInfo> getPluginSignals(){return new HashSet<>(Arrays.asList(new SignalInfo("webview_ready",String.class),new SignalInfo("ads_log_ready",String.class)));}
    @UsedByGodot public void prepare(){
        android.app.Activity activity=getActivity();
        if(activity==null){emitSignal("webview_ready","{\"ok\":false,\"message\":\"Missing Android activity\"}");return;}
        activity.runOnUiThread(()->{
            if(warmup!=null)warmup.cancel();
            warmup=new WebViewWarmup();
            warmup.begin(activity,result->emitSignal("webview_ready",result));
        });
    }
    @UsedByGodot public void read_ads_log(){
        android.app.Activity activity=getActivity();
        if(activity==null || (activity.getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)==0)return;
        if(!collecting.compareAndSet(false,true))return;
        Thread worker=new Thread(()->{
            try{emitSignal("ads_log_ready",AdLog.read(android.os.Process.myPid()));}
            finally{collecting.set(false);}
        },"neon-sdk-log");
        worker.setDaemon(true);worker.start();
    }
    @Override public void onMainDestroy(){
        if(warmup!=null)warmup.cancel();
        super.onMainDestroy();
    }
}
