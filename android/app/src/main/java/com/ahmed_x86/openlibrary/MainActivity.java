package com.ahmed_x86.openlibrary;

import android.app.NativeActivity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class MainActivity extends NativeActivity {
    
    // دوال الربط مع C++
    public native void initJni();
    public native void onFileSelected(String filePath);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // إبلاغ C++ أن التطبيق بدأ لتهيئة الجسر
        initJni();
    }

    // هذه الدالة سيستدعيها كود C++ لفتح مدير الملفات
    public void openFilePicker() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("application/epub+zip");
        String[] mimetypes = {"application/epub+zip", "application/octet-stream"};
        intent.putExtra(Intent.EXTRA_MIME_TYPES, mimetypes);
        startActivityForResult(intent, 1001);
    }

    // استقبال الملف بعد أن يختاره المستخدم
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 1001 && resultCode == RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                try {
                    // نسخ الملف المشفر إلى مسار حقيقي داخل الهاتف ليفهمه C++
                    InputStream is = getContentResolver().openInputStream(uri);
                    File tempFile = new File(getCacheDir(), "current_book.epub");
                    FileOutputStream os = new FileOutputStream(tempFile);
                    byte[] buffer = new byte[1024];
                    int length;
                    while ((length = is.read(buffer)) > 0) {
                        os.write(buffer, 0, length);
                    }
                    os.close();
                    is.close();
                    
                    // إرسال المسار الحقيقي إلى C++
                    onFileSelected(tempFile.getAbsolutePath());
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
}