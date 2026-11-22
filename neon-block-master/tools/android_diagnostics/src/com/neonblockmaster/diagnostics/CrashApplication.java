// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.diagnostics;

import android.app.Application;
import android.content.Context;
import android.os.Build;
import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;

/** Local debug reports only. No network requests and no automatic sharing. */
public final class CrashApplication extends Application {
    @Override protected void attachBaseContext(Context context) {
        super.attachBaseContext(context);
        if (Build.VERSION.SDK_INT >= 28) {
            String name=Application.getProcessName();
            if(name!=null && name.endsWith(":diagnostics")) return;
        }
        // The report screen runs separately and must never overwrite the game's report.
        try {
            android.app.ActivityManager manager=(android.app.ActivityManager)getSystemService(Context.ACTIVITY_SERVICE);
            for(android.app.ActivityManager.RunningAppProcessInfo process:manager.getRunningAppProcesses())
                if(process.pid==android.os.Process.myPid() && process.processName.endsWith(":diagnostics")) return;
        }catch(Exception ignored) { }
        final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler((thread, error) -> {
            try {
                StringWriter stack = new StringWriter();
                error.printStackTrace(new PrintWriter(stack));
                String report = "JAVA CRASH\nDevice: " + Build.MANUFACTURER + " " + Build.MODEL
                    + "\nAndroid: " + Build.VERSION.RELEASE + " / API " + Build.VERSION.SDK_INT
                    + "\nThread: " + thread.getName() + "\n\n" + stack;
                byte[] bytes = report.getBytes("UTF-8");
                File temp = new File(getFilesDir(), "neon-java-crash.tmp");
                try (FileOutputStream output = new FileOutputStream(temp)) {
                    output.write(bytes, 0, Math.min(bytes.length, 65536));
                    output.getFD().sync();
                }
                temp.renameTo(new File(getFilesDir(), "neon-java-crash.txt"));
            } catch (Throwable ignored) { /* Preserve Android's original crash handling. */ }
            if (previous != null) previous.uncaughtException(thread, error);
            else {
                android.os.Process.killProcess(android.os.Process.myPid());
                System.exit(10);
            }
        });
    }
}
