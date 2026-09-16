#include "main.h" 
#include "epub_reader.h"

#include <QApplication>
#include <QFileDialog>
#include <QDesktopServices>
#include <QUrl>

#include <iostream>
#include <memory>
#include <string>
#include <cstdlib> 
#include <optional> // تمت الإضافة لدعم التغليف والتأخير في تهيئة المتغير
#include <array>
#include <cstdio>

#ifdef __ANDROID__
#include <jni.h>
static JavaVM* g_jvm = nullptr;
static jobject g_activity = nullptr;
#endif

// استخدام std::optional لتأخير تهيئة واجهة Slint وجعلها متوافقة مع C++
static std::optional<slint::ComponentHandle<MainWindow>> g_ui;
static std::shared_ptr<EpubReader> g_reader;

// دالة تحديث الواجهة عامة
void updateReaderUI() {
    if (!g_ui || !g_reader) return;
    
    const auto& meta = g_reader->getMetadata();
    auto& ui = *g_ui; // أخذ مرجع (Reference) لتسهيل الكود وتجنب التكرار
    
    ui->set_book_title(slint::SharedString(meta.title));
    ui->set_book_author(slint::SharedString(meta.author));
    ui->set_chapter_content(slint::SharedString(g_reader->getCurrentChapterContent()));
    
    ui->set_current_chapter_num(g_reader->getCurrentChapterIndex() + 1);
    ui->set_chapter_count(g_reader->getChapterCount());
    
    ui->set_can_go_next(g_reader->getCurrentChapterIndex() + 1 < g_reader->getChapterCount());
    ui->set_can_go_prev(g_reader->getCurrentChapterIndex() > 0);
    
    ui->set_meta_language(slint::SharedString(meta.language));
    ui->set_meta_publisher(slint::SharedString(meta.publisher));
    ui->set_meta_date(slint::SharedString(meta.date));
    ui->set_meta_description(slint::SharedString(meta.description));
    ui->set_meta_subject(slint::SharedString(meta.subject));
    ui->set_meta_rights(slint::SharedString(meta.rights));
    ui->set_meta_identifier(slint::SharedString(meta.identifier));
    ui->set_meta_source(slint::SharedString(meta.source));
    ui->set_meta_format(slint::SharedString(meta.format));
    ui->set_meta_chapters(slint::SharedString(std::to_string(meta.chapterCount)));
}

// ============================================================
// Linux Desktop: نافذة اختيار ملفات أصلية عبر بوابات xdg-desktop-portal
// ============================================================
// على أنظمة Linux ذات مديري نوافذ بسيطة (مثل Hyprland على Wayland)،
// QFileDialog غالبًا يفشل في تفعيل البوابة الأصلية ويعود لنافذة Qt المدمجة.
// الحل: استخدام zenity أو kdialog مباشرة عبر popen للحصول على النافذة الأصلية دائمًا.
#if defined(__linux__) && !defined(__ANDROID__)
static std::string openNativeLinuxFileDialog() {
    // محاولة zenity أولاً (GTK/Portal)، ثم kdialog (KDE/Portal)
    const std::array<const char*, 2> commands = {
        "zenity --file-selection --title='Open EPUB Book' --file-filter='EPUB Books | *.epub' 2>/dev/null",
        "kdialog --getopenfilename . 'EPUB Books (*.epub)' --title 'Open EPUB Book' 2>/dev/null"
    };

    for (const auto* cmd : commands) {
        FILE* pipe = popen(cmd, "r");
        if (!pipe) continue;

        std::string result;
        std::array<char, 512> buffer{};
        while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
            result += buffer.data();
        }

        int status = pclose(pipe);

        // pclose يرجع حالة الخروج — 0 يعني نجاح (المستخدم اختار ملف)
        // أي قيمة أخرى تعني إلغاء أو فشل
        if (status == 0 && !result.empty()) {
            // إزالة سطر جديد من نهاية المسار
            if (result.back() == '\n') {
                result.pop_back();
            }
            return result;
        }
        // إذا الأمر الأول فشل (غير مثبت)، ننتقل للثاني
    }

    std::cerr << "[Warning] لم يتم العثور على zenity أو kdialog. تأكد من تثبيت أحدهما." << std::endl;
    return {};
}
#endif

#ifdef __ANDROID__
// ⚠️ تطبيق قاعدة JNI الصارمة: علامة _ في ahmed_x86 تتحول إلى _1 
extern "C" JNIEXPORT void JNICALL
Java_com_ahmed_1x86_openlibrary_MainActivity_initJni(JNIEnv *env, jobject thiz) {
    env->GetJavaVM(&g_jvm);
    g_activity = env->NewGlobalRef(thiz);
    std::cout << "[Android JNI] تم تهيئة جسر JNI بنجاح." << std::endl;
}

extern "C" JNIEXPORT void JNICALL
Java_com_ahmed_1x86_openlibrary_MainActivity_onFileSelected(JNIEnv *env, jobject /* this */, jstring filePath) {
    if (!g_ui || !g_reader) return;

    const char *nativeString = env->GetStringUTFChars(filePath, 0);
    std::string path(nativeString);
    env->ReleaseStringUTFChars(filePath, nativeString);

    std::cout << "[Android JNI] تم استلام مسار الملف من أندرويد: " << path << std::endl;

    // تنفيذ فتح الكتاب داخل خيط Slint الرئيسي للحماية من الانهيار
    slint::invoke_from_event_loop([path]() {
        if (g_reader->open(path)) {
            std::cout << "[Success] تم فتح الكتاب بنجاح على أندرويد!" << std::endl;
            updateReaderUI();
            (*g_ui)->set_reading_mode(true);
            (*g_ui)->set_show_info(false);
        } else {
            std::cerr << "[Error] فشل فتح الملف على أندرويد: " << path << std::endl;
        }
    });
}
#endif

#ifdef __ANDROID__
extern "C" void slint_main()
#else
int main(int argc, char* argv[])
#endif
{
#ifndef __ANDROID__
    // تهيئة Qt قبل أي شيء — ضروري حتى يعمل QFileDialog و QDesktopServices
    // لن نستدعي QApplication::exec() لأن Slint يدير حلقة الأحداث الخاصة به
    QApplication qtApp(argc, argv);
#endif

    g_ui = MainWindow::create();
    g_reader = std::make_shared<EpubReader>();
    auto& ui = *g_ui; // مرجع محلي للتعامل مع الواجهة داخل main

    ui->on_open_epub_dialog([]() {
#if defined(__linux__) && !defined(__ANDROID__)
        // Linux Desktop: استخدام zenity/kdialog لضمان نافذة أصلية عبر xdg-desktop-portal
        // هذا يتجنب مشكلة QFileDialog على مديري نوافذ بسيطة مثل Hyprland
        std::string filePath = openNativeLinuxFileDialog();

        if (!filePath.empty()) {
            if (g_reader->open(filePath)) {
                updateReaderUI();
                (*g_ui)->set_reading_mode(true);
                (*g_ui)->set_show_info(false);
            }
        }
#elif defined(__ANDROID__)
        // أمر C++ لأندرويد: افتح نافذة الملفات عبر جسر JNI
        if (g_jvm && g_activity) {
            JNIEnv* env;
            g_jvm->AttachCurrentThread(&env, NULL);
            jclass clazz = env->GetObjectClass(g_activity);
            jmethodID methodId = env->GetMethodID(clazz, "openFilePicker", "()V");
            if (methodId) {
                env->CallVoidMethod(g_activity, methodId);
            }
            g_jvm->DetachCurrentThread();
        } else {
            std::cerr << "[Error] لم يتم تهيئة JNI Activity!" << std::endl;
        }
#else
        // Windows / macOS: استخدام QFileDialog مع النافذة الأصلية للنظام
        // لا نمرر QFileDialog::DontUseNativeDialog — يستخدم النافذة الأصلية تلقائيًا
        QString filePath = QFileDialog::getOpenFileName(
            nullptr,
            QStringLiteral("Open EPUB Book"),
            QString(),
            QStringLiteral("EPUB Books (*.epub)")
        );

        if (!filePath.isEmpty()) {
            std::string path = filePath.toStdString();
            if (g_reader->open(path)) {
                updateReaderUI();
                (*g_ui)->set_reading_mode(true);
                (*g_ui)->set_show_info(false);
            }
        }
#endif
    });

    ui->on_go_next_chapter([]() {
        if (g_reader->nextChapter()) updateReaderUI();
    });

    ui->on_go_prev_chapter([]() {
        if (g_reader->prevChapter()) updateReaderUI();
    });

    ui->on_go_to_chapter([](int target_chapter) {
        int max_chapters = g_reader->getChapterCount();
        if (target_chapter < 1) target_chapter = 1;
        if (target_chapter > max_chapters) target_chapter = max_chapters;
        
        if (g_reader->goToChapter(target_chapter - 1)) {
            updateReaderUI();
        } else {
            updateReaderUI();
        }
    });

    ui->on_go_back_home([]() {
        (*g_ui)->set_reading_mode(false);
        (*g_ui)->set_show_info(false);
        g_reader->close();
    });

    ui->on_open_link([](slint::SharedString url) {
        std::string url_str(url);
#ifndef __ANDROID__
        // Qt يتكفل بفتح الرابط على Linux/Windows/macOS بشكل موحد
        QDesktopServices::openUrl(QUrl(QString::fromStdString(url_str)));
#else
        // على أندرويد نستخدم أمر النظام مباشرة لأن QApplication غير مُهيأ
        std::string cmd = "am start -a android.intent.action.VIEW -d " + url_str;
        std::system(cmd.c_str());
#endif
    });

#ifndef __ANDROID__
    if (argc > 1) {
        std::string filePath = argv[1];
        if (g_reader->open(filePath)) {
            updateReaderUI();
            ui->set_reading_mode(true);
            ui->set_show_info(false);
        }
    }
#endif

    ui->run();

#ifndef __ANDROID__
    return 0;
#endif
}