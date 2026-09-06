#include "main.h" // هذا الملف يتم توليده تلقائياً بواسطة CMake و Slint
#include "epub_reader.h"

#include <nfd.hpp>
#include <iostream>
#include <memory>
#include <string>
#include <cstdlib> // <-- تمت الإضافة لتشغيل أوامر النظام

int main() {
    // إنشاء نسخة من النافذة الرئيسية
    auto ui = MainWindow::create();

    // قارئ EPUB مشترك
    auto reader = std::make_shared<EpubReader>();

    // ============================================================
    // دالة مساعدة: تحديث واجهة القراءة
    // ============================================================
    auto updateReaderUI = [&ui, &reader]() {
        const auto& meta = reader->getMetadata();

        // البيانات الأساسية
        ui->set_book_title(slint::SharedString(meta.title));
        ui->set_book_author(slint::SharedString(meta.author));
        ui->set_chapter_content(slint::SharedString(reader->getCurrentChapterContent()));

        // تحديث أرقام الفصول للواجهة الجديدة
        ui->set_current_chapter_num(reader->getCurrentChapterIndex() + 1);
        ui->set_chapter_count(reader->getChapterCount());

        // حالة أزرار التنقل
        ui->set_can_go_next(reader->getCurrentChapterIndex() + 1 < reader->getChapterCount());
        ui->set_can_go_prev(reader->getCurrentChapterIndex() > 0);

        // البيانات الوصفية الإضافية
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
    };

    // ============================================================
    // حدث: فتح ملف EPUB
    // ============================================================
    ui->on_open_epub_dialog([&ui, &reader, &updateReaderUI]() {
        std::cout << "[Action] فتح مدير الملفات لاختيار كتاب EPUB..." << std::endl;

        NFD::Guard nfdGuard;
        nfdfilteritem_t filterItems[1] = {{"EPUB Books", "epub"}};
        NFD::UniquePath outPath;
        nfdresult_t result = NFD::OpenDialog(outPath, filterItems, 1);

        if (result == NFD_OKAY) {
            std::string filePath = outPath.get();
            std::cout << "[Action] تم اختيار: " << filePath << std::endl;

            if (reader->open(filePath)) {
                std::cout << "[Success] تم فتح الكتاب بنجاح!" << std::endl;
                updateReaderUI();
                ui->set_reading_mode(true);
                ui->set_show_info(false);
            } else {
                std::cerr << "[Error] فشل فتح الملف: " << filePath << std::endl;
            }
        } else if (result == NFD_CANCEL) {
            std::cout << "[Action] تم إلغاء اختيار الملف." << std::endl;
        } else {
            std::cerr << "[Error] خطأ في مدير الملفات: " << NFD::GetError() << std::endl;
        }
    });

    // ============================================================
    // حدث: الفصل التالي
    // ============================================================
    ui->on_go_next_chapter([&ui, &reader, &updateReaderUI]() {
        if (reader->nextChapter()) {
            updateReaderUI();
            std::cout << "[Nav] الفصل التالي: " << reader->getCurrentChapterIndex() + 1 << std::endl;
        }
    });

    // ============================================================
    // حدث: الفصل السابق
    // ============================================================
    ui->on_go_prev_chapter([&ui, &reader, &updateReaderUI]() {
        if (reader->prevChapter()) {
            updateReaderUI();
            std::cout << "[Nav] الفصل السابق: " << reader->getCurrentChapterIndex() + 1 << std::endl;
        }
    });

    // ============================================================
    // حدث: الانتقال لصفحة محددة (عن طريق الإدخال أو القائمة المنسدلة)
    // ============================================================
    ui->on_go_to_chapter([&ui, &reader, &updateReaderUI](int target_chapter) {
        int max_chapters = reader->getChapterCount();
        
        // تطبيق شروط الإدخال: لا يقل عن 1 ولا يزيد عن عدد الصفحات
        if (target_chapter < 1) target_chapter = 1;
        if (target_chapter > max_chapters) target_chapter = max_chapters;
        
        // الفهرس في C++ يبدأ من 0
        if (reader->goToChapter(target_chapter - 1)) {
            updateReaderUI();
            std::cout << "[Nav] الانتقال للفصل: " << target_chapter << std::endl;
        } else {
            // إعادة الواجهة للرقم الصحيح في حال حدوث أي خطأ غير متوقع
            updateReaderUI();
        }
    });

    // ============================================================
    // حدث: العودة للصفحة الرئيسية
    // ============================================================
    ui->on_go_back_home([&ui, &reader]() {
        ui->set_reading_mode(false);
        ui->set_show_info(false);
        reader->close();
        std::cout << "[Action] العودة للصفحة الرئيسية" << std::endl;
    });

    // ============================================================
    // حدث: فتح الروابط الخارجية (دعم لمعظم المنصات)
    // ============================================================
    ui->on_open_link([](slint::SharedString url) {
        std::string url_str(url);
        std::cout << "[Action] فتح الرابط: " << url_str << std::endl;
        
#if defined(_WIN32)
        std::string cmd = "start " + url_str;
#elif defined(__APPLE__)
        std::string cmd = "open " + url_str;
#else
        std::string cmd = "xdg-open " + url_str + " &"; // مناسب لـ Arch ولينكس عموماً
#endif
        std::system(cmd.c_str());
    });

    // تشغيل التطبيق
    ui->run();

    return 0;
}