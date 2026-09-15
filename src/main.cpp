#include "main.h" 
#include "epub_reader.h"

// مكتبة nfd لا تدعم أندرويد
#ifndef __ANDROID__
#include <nfd.hpp>
#endif

#include <iostream>
#include <memory>
#include <string>
#include <cstdlib> 
#include <optional> // تمت الإضافة لدعم التغليف والتأخير في تهيئة المتغير

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
    g_ui = MainWindow::create();
    g_reader = std::make_shared<EpubReader>();
    auto& ui = *g_ui; // مرجع محلي للتعامل مع الواجهة داخل main

    ui->on_open_epub_dialog([]() {
#ifndef __ANDROID__
        NFD::Guard nfdGuard;
        nfdfilteritem_t filterItems[1] = {{"EPUB Books", "epub"}};
        NFD::UniquePath outPath;
        nfdresult_t result = NFD::OpenDialog(outPath, filterItems, 1);

        if (result == NFD_OKAY) {
            std::string filePath = outPath.get();
            if (g_reader->open(filePath)) {
                updateReaderUI();
                (*g_ui)->set_reading_mode(true);
                (*g_ui)->set_show_info(false);
            }
        }
#else
        // أمر C++ لأندرويد: افتح نافذة الملفات الآن!
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
#if defined(_WIN32)
        std::string cmd = "start " + url_str;
#elif defined(__APPLE__)
        std::string cmd = "open " + url_str;
#elif defined(__ANDROID__)
        std::string cmd = "am start -a android.intent.action.VIEW -d " + url_str;
#else
        std::string cmd = "xdg-open " + url_str + " &";
#endif
        std::system(cmd.c_str());
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