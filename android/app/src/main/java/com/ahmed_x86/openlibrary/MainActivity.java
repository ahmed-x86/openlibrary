package com.ahmed_x86.openlibrary;

import android.app.NativeActivity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.app.Activity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

// استخدام NativeActivity لأن Slint يعتمد عليها عادة، أو Activity عادية إذا كنت تستخدم بنية مختلفة
public class MainActivity extends NativeActivity {

    private static final int FILE_SELECT_CODE = 1234;
    private static final String TAG = "OpenLibrary";

    // 1. الإعلان عن الدوال الموجودة في كود C++ (JNI)
    public native void initJni();
    public native void onFileSelected(String filePath);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 2. استدعاء دالة التهيئة لإرسال Activity و JVM إلى C++
        try {
            initJni();
            Log.i(TAG, "تم استدعاء initJni بنجاح.");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "فشل استدعاء initJni. هل تم تحميل المكتبة؟", e);
        }
    }

    // 3. هذه الدالة هي التي يستدعيها كود C++ لفتح نافذة اختيار الملفات
    public void openFilePicker() {
        Log.i(TAG, "تم طلب فتح نافذة اختيار الملفات من C++");
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("application/epub+zip"); // نطلب ملفات epub
        intent.addCategory(Intent.CATEGORY_OPENABLE);

        try {
            startActivityForResult(
                Intent.createChooser(intent, "اختر كتاب EPUB"),
                FILE_SELECT_CODE
            );
        } catch (android.content.ActivityNotFoundException ex) {
            Log.e(TAG, "لا يوجد تطبيق لإدارة الملفات مثبت على الجهاز.");
        }
    }

    private String copyFileToCache(Uri uri) {
        try {
            InputStream inputStream = getContentResolver().openInputStream(uri);
            if (inputStream == null) return null;

            File cacheDir = getCacheDir();
            File tempFile = new File(cacheDir, "temp_book.epub");
            
            FileOutputStream outputStream = new FileOutputStream(tempFile);
            byte[] buffer = new byte[8192];
            int length;
            while ((length = inputStream.read(buffer)) > 0) {
                outputStream.write(buffer, 0, length);
            }
            
            outputStream.flush();
            outputStream.close();
            inputStream.close();
            
            return tempFile.getAbsolutePath();
        } catch (Exception e) {
            Log.e(TAG, "فشل نسخ الملف إلى الكاش", e);
            return null;
        }
    }

    // 4. هذه الدالة تستقبل الملف الذي اختاره المستخدم وترسله إلى C++
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == FILE_SELECT_CODE && resultCode == Activity.RESULT_OK) {
            if (data != null) {
                Uri uri = data.getData();
                if (uri != null) {
                    Log.i(TAG, "تم اختيار الملف: " + uri.toString());
                    
                    String realPath = copyFileToCache(uri);
                    if (realPath != null) {
                        Log.i(TAG, "تم نسخ الملف بنجاح إلى: " + realPath);
                        onFileSelected(realPath);
                    } else {
                        Log.e(TAG, "فشل في الحصول على المسار الحقيقي للملف.");
                    }
                }
            }
        }
    }
}