// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.android;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

/** Bounded SDK-only log capture. No READ_LOGS permission or network transport. */
public final class AdLog {
    public static List<String> command(int pid){
        if(pid<=0)throw new IllegalArgumentException("Invalid process id");
        return Arrays.asList("logcat","-d","-b","main","-t","160","-v","brief","--pid="+pid,
            "Ads:V","chromium:W","cr_WebViewFactory:W","WebViewFactory:W","*:S");
    }
    public static String readBounded(InputStream input,int limit)throws java.io.IOException{
        ByteArrayOutputStream output=new ByteArrayOutputStream();
        byte[] buffer=new byte[1024];int count;
        while(output.size()<limit && (count=input.read(buffer,0,Math.min(buffer.length,limit-output.size())))>0)output.write(buffer,0,count);
        return output.toString("UTF-8");
    }
    public static String read(int pid){
        Process process=null;Timer timer=new Timer("neon-log-timeout",true);
        try{
            process=new ProcessBuilder(command(pid)).redirectErrorStream(true).start();
            final Process running=process;
            timer.schedule(new TimerTask(){@Override public void run(){running.destroy();}},1500);
            try(InputStream input=process.getInputStream()){
                String result=readBounded(input,16384);
                return result.trim().isEmpty()?"No additional SDK logs from this app process.":result;
            }
        }catch(Exception error){return "SDK log unavailable: "+error.getClass().getSimpleName();}
        finally{timer.cancel();if(process!=null)process.destroy();}
    }
}
