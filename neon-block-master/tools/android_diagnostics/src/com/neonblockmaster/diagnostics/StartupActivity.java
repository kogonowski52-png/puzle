// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.diagnostics;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.ApplicationExitInfo;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;

/** Separate-process launcher can show a report even when the game cannot start. */
public final class StartupActivity extends Activity {
    private long reportTime;
    private String report;

    private File file(String name) { return new File(getFilesDir(), name); }
    static byte[] read(InputStream input, int limit) throws java.io.IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int count;
        while (output.size() < limit && (count = input.read(buffer, 0, Math.min(buffer.length, limit-output.size()))) > 0)
            output.write(buffer, 0, count);
        return output.toByteArray();
    }
    private String text(File path) {
        try (InputStream input = new FileInputStream(path)) { return new String(read(input,65536),"UTF-8"); }
        catch (Exception ignored) { return ""; }
    }
    private void write(File path, byte[] data) throws java.io.IOException {
        try (FileOutputStream output = new FileOutputStream(path)) { output.write(data); }
    }
    private void startGame() {
        try { write(file("neon-crash-ack.txt"),Long.toString(reportTime).getBytes("UTF-8")); }
        catch (Exception ignored) { }
        Intent game = new Intent().setClassName(getPackageName(),"com.godot.game.GodotApp");
        startActivity(game);
        finish();
    }
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        long acknowledged = 0;
        try { acknowledged = Long.parseLong(text(file("neon-crash-ack.txt")).trim()); }
        catch (Exception ignored) { }
        StringBuilder details = new StringBuilder();
        try {
            android.content.pm.PackageInfo info = getPackageManager().getPackageInfo(getPackageName(),0);
            details.append("Neon Block Master ").append(info.versionName).append(" (code ").append(info.versionCode).append(")\n");
        } catch (Exception ignored) { }
        details.append("Device: ").append(Build.MANUFACTURER).append(' ').append(Build.MODEL)
            .append("\nAndroid: ").append(Build.VERSION.RELEASE).append(" / API ").append(Build.VERSION.SDK_INT).append('\n');
        File javaCrash = file("neon-java-crash.txt");
        if (javaCrash.lastModified() > acknowledged) {
            reportTime = javaCrash.lastModified();
            details.append('\n').append(text(javaCrash));
        }
        if (Build.VERSION.SDK_INT >= 30) reportTime = Math.max(reportTime,Api30.collect(this,acknowledged,details));
        if (reportTime <= acknowledged) { startGame(); return; }
        details.append("\n\nRaport zapisano wyłącznie na telefonie. Nie został automatycznie wysłany.");
        report = details.toString();
        try { write(file("neon-report.txt"),report.getBytes("UTF-8")); } catch (Exception ignored) { }
        LinearLayout layout = new LinearLayout(this); layout.setOrientation(LinearLayout.VERTICAL);
        float density=getResources().getDisplayMetrics().density;
        layout.setPadding((int)(24*density),(int)(48*density),(int)(24*density),(int)(28*density)); layout.setBackgroundColor(Color.rgb(8,13,30));
        TextView title = new TextView(this); title.setText("Neon Block Master — raport awarii");
        title.setTextSize(22); title.setTextColor(Color.WHITE); layout.addView(title);
        TextView message = new TextView(this); message.setText(report); message.setTextSize(13);
        message.setTextColor(Color.WHITE); message.setTextIsSelectable(true);
        ScrollView scroll = new ScrollView(this); scroll.addView(message);
        layout.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        Button copy = new Button(this); copy.setText("Kopiuj raport");
        copy.setOnClickListener(view -> {
            ((ClipboardManager)getSystemService(Context.CLIPBOARD_SERVICE)).setPrimaryClip(ClipData.newPlainText("Neon crash",report));
            Toast.makeText(this,"Raport skopiowany",Toast.LENGTH_SHORT).show();
        }); layout.addView(copy);
        Button share = new Button(this); share.setText("Udostępnij plik raportu");
        share.setOnClickListener(view -> share()); layout.addView(share);
        Button game = new Button(this); game.setText("Uruchom grę");
        game.setOnClickListener(view -> startGame()); layout.addView(game);
        setContentView(layout);
    }
    private void share() {
        ArrayList<Uri> streams = new ArrayList<>();
        for (String name : new String[]{"neon-report.txt","neon-native-trace.pb"}) {
            File path=file(name);
            if(path.isFile()) streams.add(Uri.parse("content://"+getPackageName()+".diagnostics/"+name));
        }
        if(streams.isEmpty()){Toast.makeText(this,"Nie udało się zapisać raportu",Toast.LENGTH_SHORT).show();return;}
        Intent send = new Intent(Intent.ACTION_SEND_MULTIPLE).setType("application/octet-stream");
        send.putParcelableArrayListExtra(Intent.EXTRA_STREAM,streams);
        send.putExtra(Intent.EXTRA_SUBJECT,"Neon Block Master — raport awarii");
        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        ClipData clip = ClipData.newRawUri("Neon report",streams.get(0));
        for(int i=1;i<streams.size();i++)clip.addItem(new ClipData.Item(streams.get(i)));
        send.setClipData(clip);
        startActivity(Intent.createChooser(send,"Udostępnij raport"));
    }
    @android.annotation.TargetApi(30)
    private static class Api30 {
        static long collect(StartupActivity activity,long acknowledged,StringBuilder details) {
            try {
                ActivityManager manager = (ActivityManager)activity.getSystemService(Context.ACTIVITY_SERVICE);
                for (ApplicationExitInfo exit:manager.getHistoricalProcessExitReasons(activity.getPackageName(),0,12)) {
                    if (!activity.getPackageName().equals(exit.getProcessName()) || exit.getTimestamp()<=acknowledged) continue;
                    int reason=exit.getReason();
                    if(reason!=ApplicationExitInfo.REASON_CRASH && reason!=ApplicationExitInfo.REASON_CRASH_NATIVE && reason!=ApplicationExitInfo.REASON_ANR) continue;
                    if(reason==ApplicationExitInfo.REASON_CRASH && activity.reportTime==0) return 0;
                    details.append("\nANDROID EXIT\nReason: ").append(reason).append(reason==ApplicationExitInfo.REASON_CRASH_NATIVE?" (native crash)":reason==ApplicationExitInfo.REASON_CRASH?" (Java crash)":" (ANR)")
                        .append("\nStatus / signal: ").append(exit.getStatus()).append("\nDescription: ").append(exit.getDescription()).append('\n');
                    activity.file("neon-native-trace.pb").delete();
                    // Android 12+ provides the native tombstone in protobuf format.
                    // Keep the binary intact so the developer can symbolize the real backtrace.
                    try(InputStream trace=exit.getTraceInputStream()) {
                        if(trace!=null) {
                            byte[] data=read(trace,1048576);
                            if(data.length>0) {
                                activity.write(activity.file("neon-native-trace.pb"),data);
                                details.append("Załączono ślad systemowy: neon-native-trace.pb ("+data.length+" bajtów).\n");
                            }
                        }
                    }catch(Exception ignored) { }
                    return exit.getTimestamp();
                }
            }catch(Exception error) { details.append("\nHistorical report: ").append(error.getClass().getSimpleName()).append('\n'); }
            return 0;
        }
    }
}
