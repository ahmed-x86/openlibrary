#include "epub_reader.h"

#include <zip.h>
#include <pugixml.hpp>

#include <iostream>
#include <sstream>
#include <algorithm>
#include <functional>
#include <filesystem>

// ============================================================
// قراءة ملف من داخل أرشيف ZIP
// ============================================================
std::string EpubReader::readFileFromZip(const std::string& zipPath, const std::string& innerPath) {
    int err = 0;
    zip_t* archive = zip_open(zipPath.c_str(), ZIP_RDONLY, &err);
    if (!archive) {
        std::cerr << "[EPUB] فشل فتح الأرشيف: " << zipPath << std::endl;
        return "";
    }

    // البحث عن الملف داخل الأرشيف
    zip_int64_t index = zip_name_locate(archive, innerPath.c_str(), 0);
    if (index < 0) {
        // محاولة بحث بدون حساسية لحالة الأحرف
        index = zip_name_locate(archive, innerPath.c_str(), ZIP_FL_NOCASE);
    }

    if (index < 0) {
        std::cerr << "[EPUB] لم يُعثر على الملف: " << innerPath << std::endl;
        zip_close(archive);
        return "";
    }

    // الحصول على معلومات الملف
    struct zip_stat st;
    zip_stat_init(&st);
    zip_stat_index(archive, static_cast<zip_uint64_t>(index), 0, &st);

    // قراءة المحتوى
    zip_file_t* zf = zip_fopen_index(archive, static_cast<zip_uint64_t>(index), 0);
    if (!zf) {
        std::cerr << "[EPUB] فشل فتح الملف داخل الأرشيف: " << innerPath << std::endl;
        zip_close(archive);
        return "";
    }

    std::string content(st.size, '\0');
    zip_fread(zf, content.data(), st.size);
    zip_fclose(zf);
    zip_close(archive);

    return content;
}

// ============================================================
// تحليل container.xml
// ============================================================
std::string EpubReader::parseContainerXml(const std::string& xml) {
    pugi::xml_document doc;
    pugi::xml_parse_result result = doc.load_string(xml.c_str());

    if (!result) {
        std::cerr << "[EPUB] فشل تحليل container.xml: " << result.description() << std::endl;
        return "";
    }

    // البحث عن rootfile - نبحث بعدة طرق لدعم EPUB مختلفة
    // أولاً: بحث مباشر بالمساحة الاسمية
    auto rootfile = doc.select_node("//rootfile");
    if (!rootfile) {
        // محاولة بدون مساحة اسمية
        rootfile = doc.select_node("//*[local-name()='rootfile']");
    }

    if (rootfile) {
        std::string fullPath = rootfile.node().attribute("full-path").as_string();
        if (!fullPath.empty()) {
            return fullPath;
        }
    }

    // محاولة أخيرة: بحث يدوي
    for (auto& child : doc.children()) {
        for (auto& rootfiles : child.children()) {
            for (auto& rf : rootfiles.children()) {
                auto attr = rf.attribute("full-path");
                if (attr) {
                    return attr.as_string();
                }
            }
        }
    }

    std::cerr << "[EPUB] لم يُعثر على مسار OPF في container.xml" << std::endl;
    return "";
}

// ============================================================
// دالة مساعدة: استخراج نص من عقدة metadata بالاسم المحلي
// ============================================================
static std::string extractMetaField(const pugi::xml_node& metadata, const std::string& localName) {
    std::string xpath = ".//*[local-name()='" + localName + "']";
    auto node = metadata.select_node(xpath.c_str());
    if (node) {
        return node.node().text().as_string();
    }
    return "";
}

// ============================================================
// تحليل ملف OPF
// ============================================================
bool EpubReader::parseOpf(const std::string& zipPath, const std::string& opfPath) {
    std::string opfContent = readFileFromZip(zipPath, opfPath);
    if (opfContent.empty()) {
        return false;
    }

    // استخراج مجلد OPF للمسارات النسبية
    auto lastSlash = opfPath.find_last_of('/');
    m_opf_dir = (lastSlash != std::string::npos) ? opfPath.substr(0, lastSlash + 1) : "";

    pugi::xml_document doc;
    pugi::xml_parse_result result = doc.load_string(opfContent.c_str());

    if (!result) {
        std::cerr << "[EPUB] فشل تحليل OPF: " << result.description() << std::endl;
        return false;
    }

    // --- استخراج الميتاداتا الكاملة ---
    auto metadataNode = doc.select_node("//*[local-name()='metadata']");
    if (metadataNode) {
        auto meta = metadataNode.node();
        m_metadata.title       = extractMetaField(meta, "title");
        m_metadata.author      = extractMetaField(meta, "creator");
        m_metadata.language    = extractMetaField(meta, "language");
        m_metadata.publisher   = extractMetaField(meta, "publisher");
        m_metadata.date        = extractMetaField(meta, "date");
        m_metadata.description = extractMetaField(meta, "description");
        m_metadata.subject     = extractMetaField(meta, "subject");
        m_metadata.rights      = extractMetaField(meta, "rights");
        m_metadata.identifier  = extractMetaField(meta, "identifier");
        m_metadata.source      = extractMetaField(meta, "source");
        m_metadata.format      = extractMetaField(meta, "format");
    }

    if (m_metadata.title.empty()) m_metadata.title = "كتاب بدون عنوان";
    if (m_metadata.author.empty()) m_metadata.author = "مؤلف مجهول";

    // --- بناء خريطة manifest (id → href) ---
    struct ManifestItem {
        std::string id;
        std::string href;
        std::string mediaType;
    };
    std::vector<ManifestItem> manifestItems;

    auto manifest = doc.select_node("//*[local-name()='manifest']");
    if (manifest) {
        for (auto& item : manifest.node().children()) {
            if (std::string(item.name()).find("item") != std::string::npos ||
                std::string(item.attribute("href").as_string()).length() > 0) {
                ManifestItem mi;
                mi.id = item.attribute("id").as_string();
                mi.href = item.attribute("href").as_string();
                mi.mediaType = item.attribute("media-type").as_string();
                manifestItems.push_back(mi);
            }
        }
    }

    // --- قراءة ترتيب الفصول من spine ---
    auto spine = doc.select_node("//*[local-name()='spine']");
    if (spine) {
        for (auto& itemref : spine.node().children()) {
            std::string idref = itemref.attribute("idref").as_string();
            if (idref.empty()) continue;

            // البحث عن الملف المقابل في manifest
            for (auto& mi : manifestItems) {
                if (mi.id == idref && mi.mediaType.find("xhtml") != std::string::npos) {
                    EpubChapter chapter;
                    chapter.id = mi.id;
                    chapter.href = m_opf_dir + mi.href;
                    chapter.title = "الفصل " + std::to_string(m_chapters.size() + 1);
                    m_chapters.push_back(chapter);
                    break;
                }
            }
        }
    }

    // إذا لم يجد فصول من spine، نأخذ كل ملفات XHTML من manifest
    if (m_chapters.empty()) {
        for (auto& mi : manifestItems) {
            if (mi.mediaType.find("xhtml") != std::string::npos ||
                mi.mediaType.find("html") != std::string::npos) {
                EpubChapter chapter;
                chapter.id = mi.id;
                chapter.href = m_opf_dir + mi.href;
                chapter.title = "الفصل " + std::to_string(m_chapters.size() + 1);
                m_chapters.push_back(chapter);
            }
        }
    }

    m_metadata.chapterCount = static_cast<int>(m_chapters.size());

    return !m_chapters.empty();
}

// ============================================================
// تحويل XHTML إلى نص عادي
// ============================================================
std::string EpubReader::xhtmlToPlainText(const std::string& xhtml) {
    pugi::xml_document doc;
    // نستخدم parse_default مع parse_ws_pcdata لنحافظ على المسافات
    doc.load_string(xhtml.c_str(), pugi::parse_default | pugi::parse_ws_pcdata);

    std::ostringstream result;

    // دالة تمشي على كل العقد وتستخرج النص
    std::function<void(const pugi::xml_node&)> extractText;
    extractText = [&](const pugi::xml_node& node) {
        for (auto& child : node.children()) {
            if (child.type() == pugi::node_pcdata || child.type() == pugi::node_cdata) {
                std::string text = child.value();
                // تنظيف المسافات الزائدة
                if (!text.empty()) {
                    result << text;
                }
            } else if (child.type() == pugi::node_element) {
                std::string name = child.name();

                // إضافة سطر جديد قبل العناصر الكتلية
                if (name == "p" || name == "div" || name == "br" ||
                    name == "h1" || name == "h2" || name == "h3" ||
                    name == "h4" || name == "h5" || name == "h6" ||
                    name == "li" || name == "blockquote" || name == "tr") {
                    result << "\n";
                }

                // إضافة علامة للعناوين
                if (name == "h1" || name == "h2" || name == "h3") {
                    result << "\n━━━ ";
                }

                extractText(child);

                if (name == "h1" || name == "h2" || name == "h3") {
                    result << " ━━━\n";
                }

                // سطر جديد بعد الفقرات
                if (name == "p" || name == "div" ||
                    name == "h1" || name == "h2" || name == "h3" ||
                    name == "h4" || name == "h5" || name == "h6") {
                    result << "\n";
                }

                // نقطة قبل عناصر القائمة
                if (name == "li") {
                    result << "\n";
                }
            }
        }
    };

    extractText(doc);

    // تنظيف النتيجة: إزالة الأسطر الفارغة المتكررة
    std::string text = result.str();
    std::string cleaned;
    bool lastWasNewline = false;
    bool lastWasDouble = false;

    for (char c : text) {
        if (c == '\n') {
            if (!lastWasNewline) {
                cleaned += '\n';
                lastWasNewline = true;
                lastWasDouble = false;
            } else if (!lastWasDouble) {
                cleaned += '\n';
                lastWasDouble = true;
            }
            // تجاهل أكثر من سطرين فارغين متتاليين
        } else {
            cleaned += c;
            lastWasNewline = false;
            lastWasDouble = false;
        }
    }

    // إزالة المسافات في بداية ونهاية النص
    auto start = cleaned.find_first_not_of(" \t\n\r");
    auto end = cleaned.find_last_not_of(" \t\n\r");
    if (start == std::string::npos) return "";
    return cleaned.substr(start, end - start + 1);
}

// ============================================================
// فتح ملف EPUB
// ============================================================
bool EpubReader::open(const std::string& filepath) {
    close(); // إغلاق أي كتاب مفتوح

    m_filepath = filepath;

    // الخطوة 1: قراءة container.xml
    std::string containerXml = readFileFromZip(filepath, "META-INF/container.xml");
    if (containerXml.empty()) {
        std::cerr << "[EPUB] لم يُعثر على META-INF/container.xml" << std::endl;
        return false;
    }

    // الخطوة 2: الحصول على مسار OPF
    std::string opfPath = parseContainerXml(containerXml);
    if (opfPath.empty()) {
        std::cerr << "[EPUB] لم يُعثر على مسار OPF" << std::endl;
        return false;
    }

    std::cout << "[EPUB] ملف OPF: " << opfPath << std::endl;

    // الخطوة 3: تحليل OPF
    if (!parseOpf(filepath, opfPath)) {
        std::cerr << "[EPUB] فشل تحليل OPF أو لا توجد فصول" << std::endl;
        return false;
    }

    std::cout << "[EPUB] تم فتح: " << m_metadata.title << " بواسطة " << m_metadata.author << std::endl;
    std::cout << "[EPUB] عدد الفصول: " << m_chapters.size() << std::endl;

    // الخطوة 4: تحميل محتوى الفصل الأول
    if (!m_chapters.empty()) {
        std::string xhtml = readFileFromZip(filepath, m_chapters[0].href);
        m_chapters[0].content = xhtmlToPlainText(xhtml);
    }

    m_current_chapter = 0;
    m_is_open = true;

    return true;
}

// ============================================================
// محتوى الفصل الحالي
// ============================================================
std::string EpubReader::getCurrentChapterTitle() const {
    if (m_chapters.empty() || m_current_chapter < 0 ||
        m_current_chapter >= static_cast<int>(m_chapters.size())) {
        return "";
    }
    return m_chapters[m_current_chapter].title;
}

std::string EpubReader::getCurrentChapterContent() const {
    if (m_chapters.empty() || m_current_chapter < 0 ||
        m_current_chapter >= static_cast<int>(m_chapters.size())) {
        return "";
    }
    return m_chapters[m_current_chapter].content;
}

// ============================================================
// التنقل بين الفصول
// ============================================================
bool EpubReader::nextChapter() {
    if (m_current_chapter + 1 >= static_cast<int>(m_chapters.size())) {
        return false;
    }
    return goToChapter(m_current_chapter + 1);
}

bool EpubReader::prevChapter() {
    if (m_current_chapter <= 0) {
        return false;
    }
    return goToChapter(m_current_chapter - 1);
}

bool EpubReader::goToChapter(int index) {
    if (index < 0 || index >= static_cast<int>(m_chapters.size())) {
        return false;
    }

    m_current_chapter = index;

    // تحميل المحتوى إذا لم يكن محملاً
    if (m_chapters[index].content.empty()) {
        std::string xhtml = readFileFromZip(m_filepath, m_chapters[index].href);
        m_chapters[index].content = xhtmlToPlainText(xhtml);
    }

    return true;
}

// ============================================================
// إغلاق الكتاب
// ============================================================
void EpubReader::close() {
    m_is_open = false;
    m_filepath.clear();
    m_metadata = EpubMetadata{};
    m_opf_dir.clear();
    m_chapters.clear();
    m_current_chapter = 0;
}
