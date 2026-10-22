package com.ahmed_x86.openlibrary;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

// Qt6: يجب أن يرث QtActivity. هو الذي يحمّل مكتبات Qt ومكتبة التطبيق
// (libopenlibrary_<abi>.so) وينشئ سطح الرسم. NativeActivity لا يشغّل Qt.
public class MainActivity extends QtActivity {

    private static final int FILE_SELECT_CODE = 1234;
    private static final String TAG = "OpenLibrary";

    private boolean jniReady = false;

    // دوال JNI المعرّفة في src/main.cpp
    public native void initJNI();
    public native void onEpubFileSelected(String filePath);

    // ملاحظة: لا يوجد System.loadLibrary هنا، فـ QtActivity يتولى التحميل.

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        tryInitJni();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!jniReady) tryInitJni();   // إعادة محاولة إن لم تكن المكتبة جاهزة في onCreate
    }

    private void tryInitJni() {
        try {
            initJNI();
            jniReady = true;
            Log.i(TAG, "تم استدعاء initJNI بنجاح.");
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "initJNI غير جاهزة بعد (المكتبة لم تُحمَّل). ستُعاد المحاولة.", e);
        }
    }

    // يستدعيها C++ من خيط Qt، لذلك ننقل الطلب إلى خيط الواجهة
    public void openFilePicker() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
                intent.setType("application/epub+zip");
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                try {
                    startActivityForResult(
                        Intent.createChooser(intent, "اختر كتاب EPUB"),
                        FILE_SELECT_CODE
                    );
                } catch (ActivityNotFoundException ex) {
                    Log.e(TAG, "لا يوجد تطبيق لإدارة الملفات مثبت على الجهاز.");
                }
            }
        });
    }

    private String copyFileToCache(Uri uri) {
        try (InputStream in = getContentResolver().openInputStream(uri)) {
            if (in == null) return null;
            File tempFile = new File(getCacheDir(), "temp_book.epub");
            try (FileOutputStream out = new FileOutputStream(tempFile)) {
                byte[] buffer = new byte[8192];
                int length;
                while ((length = in.read(buffer)) > 0) {
                    out.write(buffer, 0, length);
                }
                out.flush();
            }
            return tempFile.getAbsolutePath();
        } catch (Exception e) {
            Log.e(TAG, "فشل نسخ الملف إلى الكاش", e);
            return null;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == FILE_SELECT_CODE && resultCode == Activity.RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                String realPath = copyFileToCache(uri);
                if (realPath != null) {
                    onEpubFileSelected(realPath);
                } else {
                    Log.e(TAG, "فشل في الحصول على المسار الحقيقي للملف.");
                }
            }
        }
    }
}