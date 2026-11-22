// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Neon Block Master contributors.
package com.neonblockmaster.diagnostics;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;
import java.io.File;
import java.io.FileNotFoundException;

/** Only two fixed report files, read-only, with an explicit temporary URI grant. */
public final class ReportProvider extends ContentProvider {
    @Override public boolean onCreate(){return true;}
    private File file(Uri uri) throws FileNotFoundException {
        String path=uri.getPath();
        if(!"/neon-report.txt".equals(path) && !"/neon-native-trace.pb".equals(path)) throw new FileNotFoundException("Unknown report");
        return new File(getContext().getFilesDir(),path.substring(1));
    }
    @Override public ParcelFileDescriptor openFile(Uri uri,String mode) throws FileNotFoundException {
        if(!"r".equals(mode))throw new FileNotFoundException("Read only");
        return ParcelFileDescriptor.open(file(uri),ParcelFileDescriptor.MODE_READ_ONLY);
    }
    @Override public String getType(Uri uri){return uri.getPath().endsWith(".txt")?"text/plain":"application/octet-stream";}
    @Override public Cursor query(Uri uri,String[] projection,String selection,String[] args,String sort){
        MatrixCursor cursor=new MatrixCursor(new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE});
        try {File path=file(uri);cursor.addRow(new Object[]{path.getName(),path.length()});}catch(FileNotFoundException ignored){}
        return cursor;
    }
    @Override public Uri insert(Uri uri,ContentValues values){throw new UnsupportedOperationException();}
    @Override public int update(Uri uri,ContentValues values,String selection,String[] args){throw new UnsupportedOperationException();}
    @Override public int delete(Uri uri,String selection,String[] args){throw new UnsupportedOperationException();}
}
