package com.ahmed_x86.openlibrary;

import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.OpenableColumns;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * النشاط الرئيسي لـ OpenLibrary.
 *  - يستقبل "فتح بواسطة OpenLibrary" (ACTION_VIEW / ACTION_SEND) سواء عند التشغيل أو والتطبيق مفتوح.
 *  - يوفّر منتقي الملفات openFilePicker() الذي يستدعيه كود C++.
 *  - يحوّل أي content:// إلى ملف في الكاش لأن C++ يقرأ مساراً حقيقياً.
 */
public class MainActivity extends QtActivity {
    private static final String TAG = "OpenLibrary";
    private static final int REQ_PICK_EPUB = 4242;

    // دوال JNI المعرّفة في main.cpp
    public native void initJNI();
    public native void onEpubFileSelected(String path);

    private boolean nativeReady = false;
    private Intent pendingIntent = null;
    private final Handler retryHandler = new Handler(Looper.getMainLooper());
    private int retryCount = 0;
    private static final int MAX_RETRIES = 50;      // 50 × 300ms = 15 ثانية
    private static final long RETRY_DELAY_MS = 300;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        pendingIntent = getIntent();
        tryInitNative();
        processPendingIntent();
    }

    @Override
    protected void onResume() {
        super.onResume();
        tryInitNative();
        processPendingIntent();
    }

    // التطبيق مفتوح أصلاً وجاءه كتاب جديد من "فتح بواسطة"
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        pendingIntent = intent;
        tryInitNative();
        processPendingIntent();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_PICK_EPUB && resultCode == RESULT_OK && data != null) {
            final Uri uri = data.getData();
            if (uri != null) {
                importAndOpen(uri);
            }
        }
    }

    /** يُستدعى من C++ (خيط Qt) عند الضغط على "فتح كتاب" */
    public void openFilePicker() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                    i.addCategory(Intent.CATEGORY_OPENABLE);
                    i.setType("*/*");
                    i.putExtra(Intent.EXTRA_MIME_TYPES,
                            new String[]{"application/epub+zip", "application/octet-stream"});
                    startActivityForResult(i, REQ_PICK_EPUB);
                } catch (Exception e) {
                    Log.e(TAG, "فشل فتح منتقي الملفات", e);
                }
            }
        });
    }

    // ------------------------------------------------------------------

    private void tryInitNative() {
        if (nativeReady) return;
        try {
            initJNI();
            nativeReady = true;
        } catch (UnsatisfiedLinkError e) {
            // مكتبة Qt لم تُحمَّل بعد؛ نعيد المحاولة في onResume
            Log.w(TAG, "مكتبة C++ غير جاهزة بعد: " + e.getMessage());
        }
    }

    private void processPendingIntent() {
        if (pendingIntent == null) return;
        if (!nativeReady) {
            // مكتبة Qt لم تجهز بعد: نعيد المحاولة تلقائياً بدل انتظار حدث دورة حياة آخر
            if (retryCount++ < MAX_RETRIES) {
                retryHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        tryInitNative();
                        processPendingIntent();
                    }
                }, RETRY_DELAY_MS);
            } else {
                Log.e(TAG, "انتهت مهلة انتظار تحميل مكتبة C++، لن يُفتح الكتاب تلقائياً");
            }
            return;
        }
        retryCount = 0;
        Intent intent = pendingIntent;
        pendingIntent = null;

        Uri uri = extractUri(intent);
        if (uri != null) {
            // لا نعالج نفس الـ Intent مرتين (مثلاً بعد العودة من الخلفية)
            setIntent(new Intent(Intent.ACTION_MAIN));
            importAndOpen(uri);
        }
    }

    @SuppressWarnings("deprecation")
    private Uri extractUri(Intent intent) {
        if (intent == null) return null;
        String action = intent.getAction();
        if (Intent.ACTION_VIEW.equals(action)) {
            return intent.getData();
        }
        if (Intent.ACTION_SEND.equals(action)) {
            Object stream = intent.getParcelableExtra(Intent.EXTRA_STREAM);
            if (stream instanceof Uri) return (Uri) stream;
        }
        return null;
    }

    /** ينسخ الملف إلى الكاش في خيط خلفي ثم يسلّم المسار لـ C++ */
    private void importAndOpen(final Uri uri) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String path = copyToCache(uri);
                    if (path != null) {
                        onEpubFileSelected(path);
                    }
                } catch (Throwable t) {
                    Log.e(TAG, "فشل استيراد الكتاب", t);
                }
            }
        }, "openlibrary-import").start();
    }

    private String copyToCache(Uri uri) throws Exception {
        if ("file".equals(uri.getScheme()) && uri.getPath() != null) {
            File f = new File(uri.getPath());
            if (f.canRead()) return f.getAbsolutePath();
        }

        String name = queryDisplayName(uri);
        if (name == null || name.trim().isEmpty()) name = "book.epub";
        name = name.replaceAll("[\\\\/:*?\"<>|]", "_");
        // حماية من أسماء خطيرة مثل ".." أو "."
        if (name.equals(".") || name.equals("..")) name = "book.epub";

        File dir = new File(getCacheDir(), "imports");
        if (!dir.exists() && !dir.mkdirs()) {
            Log.e(TAG, "تعذّر إنشاء مجلد الاستيراد");
            return null;
        }
        File out = new File(dir, name);

        // تنظيف الكتب المستوردة القديمة (أقدم من 7 أيام) حتى لا يكبر الكاش
        File[] old = dir.listFiles();
        if (old != null) {
            long limit = System.currentTimeMillis() - 7L * 24 * 60 * 60 * 1000;
            for (File f : old) {
                if (!f.equals(out) && f.lastModified() < limit) {
                    //noinspection ResultOfMethodCallIgnored
                    f.delete();
                }
            }
        }

        boolean ok = false;
        try (InputStream in = getContentResolver().openInputStream(uri);
             OutputStream os = new FileOutputStream(out)) {
            if (in == null) return null;
            byte[] buf = new byte[64 * 1024];
            int n;
            while ((n = in.read(buf)) > 0) {
                os.write(buf, 0, n);
            }
            ok = true;
        } finally {
            // لا نترك ملفاً ناقصاً لو فشل النسخ في المنتصف
            if (!ok && out.exists()) {
                //noinspection ResultOfMethodCallIgnored
                out.delete();
            }
        }
        return out.getAbsolutePath();
    }

    private String queryDisplayName(Uri uri) {
        try (Cursor c = getContentResolver().query(uri, null, null, null, null)) {
            if (c != null && c.moveToFirst()) {
                int idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (idx >= 0) return c.getString(idx);
            }
        } catch (Exception ignored) {
        }
        return uri.getLastPathSegment();
    }
}