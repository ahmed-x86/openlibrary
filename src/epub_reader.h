#pragma once

#include <string>
#include <vector>
#include <cstdint>

// ============================================================
// هيكل يمثل فصل واحد من الكتاب
// ============================================================
struct EpubChapter {
    std::string id;       // معرف الفصل من manifest
    std::string href;     // مسار ملف XHTML داخل الأرشيف
    std::string title;    // عنوان الفصل (إن وجد)
    std::string content;  // محتوى الفصل كنص عادي
};

// ============================================================
// هيكل يحتوي جميع بيانات الكتاب (Metadata)
// ============================================================
struct EpubMetadata {
    std::string title;
    std::string author;
    std::string language;
    std::string publisher;
    std::string date;
    std::string description;
    std::string subject;
    std::string rights;
    std::string identifier; // ISBN أو معرف آخر
    std::string source;
    std::string format;
    int chapterCount = 0;
};

// ============================================================
// كلاس قارئ EPUB
// ============================================================
class EpubReader {
public:
    EpubReader() = default;
    ~EpubReader() = default;

    // فتح ملف EPUB وتحليله
    bool open(const std::string& filepath);

    // هل الملف مفتوح؟
    bool isOpen() const { return m_is_open; }

    // بيانات الكتاب
    std::string getTitle() const { return m_metadata.title; }
    std::string getAuthor() const { return m_metadata.author; }
    std::string getLanguage() const { return m_metadata.language; }

    // جميع البيانات الوصفية
    const EpubMetadata& getMetadata() const { return m_metadata; }

    // الفصول
    int getChapterCount() const { return static_cast<int>(m_chapters.size()); }
    int getCurrentChapterIndex() const { return m_current_chapter; }

    // محتوى الفصل الحالي
    std::string getCurrentChapterTitle() const;
    std::string getCurrentChapterContent() const;

    // التنقل بين الفصول
    bool nextChapter();
    bool prevChapter();
    bool goToChapter(int index);

    // إغلاق الكتاب
    void close();

private:
    // قراءة ملف من داخل أرشيف ZIP
    std::string readFileFromZip(const std::string& zipPath, const std::string& innerPath);

    // تحليل container.xml للحصول على مسار ملف OPF
    std::string parseContainerXml(const std::string& xml);

    // تحليل ملف OPF لاستخراج الميتاداتا والفصول
    bool parseOpf(const std::string& zipPath, const std::string& opfPath);

    // تحويل XHTML إلى نص عادي (إزالة الوسوم)
    std::string xhtmlToPlainText(const std::string& xhtml);

    // حالة الكتاب
    bool m_is_open = false;
    std::string m_filepath;
    EpubMetadata m_metadata;
    std::string m_opf_dir; // المجلد الذي يحتوي ملف OPF (للمسارات النسبية)

    // الفصول
    std::vector<EpubChapter> m_chapters;
    int m_current_chapter = 0;
};
