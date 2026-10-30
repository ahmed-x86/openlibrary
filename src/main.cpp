#include "epub_reader.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlPropertyMap>
#include <QQmlExpression>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QFileDialog>
#include <QDesktopServices>
#include <QStandardPaths>
#include <QMetaObject>
#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QUrl>

#include <iostream>
#include <memory>
#include <string>
#include <array>
#include <cstdio>
#include <mutex>

#ifdef __ANDROID__
#include <jni.h>
static JavaVM* g_jvm = nullptr;
static jobject g_activity = nullptr;
#endif

static QObject* g_rootObject = nullptr;
static std::shared_ptr<EpubReader> g_reader;

// مسار كتاب وصل من أندرويد (فتح بواسطة...) قبل أن تجهز واجهة QML
static std::mutex g_pendingMutex;
static bool g_uiReady = false;
static std::string g_pendingBookPath;

// وراثة QQmlPropertyMap عبر الباني المحمي لمنع تحذير الإهمال (Deprecation Warning) في Qt 6.10+
class BridgeMap : public QQmlPropertyMap {
public:
    explicit BridgeMap(QObject* parent = nullptr)
        : QQmlPropertyMap(this, parent) {}
};

// ============================================================
// تحديث خصائص واجهة QML من بيانات الكتاب الحالي
// ============================================================
void updateReaderUI() {
    if (!g_rootObject || !g_reader) return;

    const auto& meta = g_reader->getMetadata();

    g_rootObject->setProperty("bookTitle", QString::fromStdString(meta.title));
    g_rootObject->setProperty("bookAuthor", QString::fromStdString(meta.author));
    g_rootObject->setProperty("chapterContent", QString::fromStdString(g_reader->getCurrentChapterContent()));

    g_rootObject->setProperty("currentChapterNum", g_reader->getCurrentChapterIndex() + 1);
    g_rootObject->setProperty("chapterCount", g_reader->getChapterCount());

    g_rootObject->setProperty("canGoNext", g_reader->getCurrentChapterIndex() + 1 < g_reader->getChapterCount());
    g_rootObject->setProperty("canGoPrev", g_reader->getCurrentChapterIndex() > 0);

    g_rootObject->setProperty("metaLanguage", QString::fromStdString(meta.language));
    g_rootObject->setProperty("metaPublisher", QString::fromStdString(meta.publisher));
    g_rootObject->setProperty("metaDate", QString::fromStdString(meta.date));
    g_rootObject->setProperty("metaDescription", QString::fromStdString(meta.description));
    g_rootObject->setProperty("metaSubject", QString::fromStdString(meta.subject));
    g_rootObject->setProperty("metaRights", QString::fromStdString(meta.rights));
    g_rootObject->setProperty("metaIdentifier", QString::fromStdString(meta.identifier));
    g_rootObject->setProperty("metaSource", QString::fromStdString(meta.source));
    g_rootObject->setProperty("metaFormat", QString::fromStdString(meta.format));
    g_rootObject->setProperty("metaChapters", QString::number(meta.chapterCount));
}

// ============================================================
// فتح كتاب وتفعيل وضع القراءة
// ============================================================
static bool openBookAndShow(const std::string& filePath) {
    if (filePath.empty() || !g_reader || !g_rootObject) return false;

    if (g_reader->open(filePath)) {
        updateReaderUI();
        g_rootObject->setProperty("readingMode", true);
        g_rootObject->setProperty("showInfo", false);
        g_rootObject->setProperty("editingChapter", false);
        g_rootObject->setProperty("dropdownOpen", false);
        return true;
    }

    std::cerr << "[Error] فشل فتح ملف الكتاب: " << filePath << std::endl;
    return false;
}

// ============================================================
// Linux Desktop: نافذة اختيار ملفات أصلية عبر zenity / kdialog
// مع التراجع التلقائي إلى QFileDialog إذا لم يكونا مثبتين
// ============================================================
#if defined(__linux__) && !defined(__ANDROID__)
static std::string openNativeLinuxFileDialog(bool& handledByExternalTool) {
    handledByExternalTool = false;

    struct DialogCmd {
        const char* binary;
        const char* command;
    };

    const std::array<DialogCmd, 2> tools = {{
        {"zenity",  "zenity --file-selection --title='Open EPUB Book' --file-filter='EPUB Books | *.epub' 2>/dev/null"},
        {"kdialog", "kdialog --getopenfilename . 'EPUB Books (*.epub)' --title 'Open EPUB Book' 2>/dev/null"}
    }};

    for (const auto& tool : tools) {
        if (QStandardPaths::findExecutable(QString::fromLatin1(tool.binary)).isEmpty()) {
            continue;
        }

        handledByExternalTool = true;
        FILE* pipe = popen(tool.command, "r");
        if (!pipe) continue;

        std::string result;
        std::array<char, 512> buffer{};
        while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
            result += buffer.data();
        }

        int status = pclose(pipe);
        if (status == 0 && !result.empty()) {
            while (!result.empty() && (result.back() == '\n' || result.back() == '\r')) {
                result.pop_back();
            }
            return result;
        }
        // المستخدم ضغط إلغاء في الأداة المتوفرة، لا نفتح الأداة الثانية
        return {};
    }

    return {};
}
#endif

// ============================================================
// دوال JNI الخاصة بنظام أندرويد
// ============================================================
#ifdef __ANDROID__
extern "C" JNIEXPORT void JNICALL
Java_com_ahmed_1x86_openlibrary_MainActivity_initJNI(JNIEnv* env, jobject thiz) {
    env->GetJavaVM(&g_jvm);
    if (g_activity) {
        env->DeleteGlobalRef(g_activity);
    }
    g_activity = env->NewGlobalRef(thiz);
    std::cout << "[Android JNI] تم تهيئة جسر JNI بنجاح." << std::endl;
}

extern "C" JNIEXPORT void JNICALL
Java_com_ahmed_1x86_openlibrary_MainActivity_onEpubFileSelected(JNIEnv* env, jobject /* thiz */, jstring filePath) {
    if (!filePath) return;

    const char* nativeString = env->GetStringUTFChars(filePath, nullptr);
    std::string path(nativeString ? nativeString : "");
    env->ReleaseStringUTFChars(filePath, nativeString);
    if (path.empty()) return;

    std::cout << "[Android JNI] تم استلام مسار الملف من أندرويد: " << path << std::endl;

    {
        // لو الواجهة لم تجهز بعد (تشغيل مباشر من "فتح بواسطة") نحفظ المسار ويُفتح بعد التحميل
        std::lock_guard<std::mutex> lock(g_pendingMutex);
        if (!g_uiReady || !g_rootObject) {
            g_pendingBookPath = path;
            return;
        }
    }

    // تنفيذ فتح الكتاب داخل خيط Qt الرئيسي بأمان
    QMetaObject::invokeMethod(g_rootObject, [path]() {
        openBookAndShow(path);
    }, Qt::QueuedConnection);
}
#endif

// ============================================================
// تحديد مسار ملف main.qml (من الموارد المدمجة أو من المجلد المحلي)
// ============================================================
static QUrl resolveMainQmlUrl() {
    if (QFile::exists(QStringLiteral(":/ui/main.qml"))) {
        return QUrl(QStringLiteral("qrc:/ui/main.qml"));
    }
    if (QFile::exists(QStringLiteral(":/main.qml"))) {
        return QUrl(QStringLiteral("qrc:/main.qml"));
    }

    const QStringList searchPaths = {
        QDir::currentPath() + QStringLiteral("/ui/main.qml"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/ui/main.qml"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../ui/main.qml")
    };

    for (const QString& path : searchPaths) {
        if (QFileInfo::exists(path)) {
            return QUrl::fromLocalFile(QFileInfo(path).absoluteFilePath());
        }
    }

    return QUrl(QStringLiteral("qrc:/ui/main.qml"));
}

// ============================================================
// الدالة الرئيسية الموحدة (Linux / Windows / macOS / Android)
// ============================================================
int main(int argc, char* argv[]) {
    // توحيد طابع عناصر التحكم عبر كل الأنظمة لضمان تطابق ألوان الوضع الليلي/النهاري
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("OpenLibrary"));
    app.setOrganizationName(QStringLiteral("ahmed-x86"));

    g_reader = std::make_shared<EpubReader>();

    QQmlApplicationEngine engine;

    // 1. إنشاء كائن Theme وتعميمه على كافة ملفات QML لضمان عمل الألوان والوضع الليلي/النهاري
    QQmlComponent themeComp(&engine);
    themeComp.setData(R"QML(
        import QtQuick
        QtObject {
            property bool isDark: true
            readonly property color bg: isDark ? "#09090b" : "#ffffff"
            readonly property color surface: isDark ? "#121215" : "#f4f4f5"
            readonly property color border: isDark ? "#27272a" : "#e4e4e7"
            readonly property color text: isDark ? "#f4f4f5" : "#09090b"
            readonly property color textMuted: isDark ? "#a1a1aa" : "#71717a"
            readonly property color buttonBg: isDark ? "#18181b" : "#ffffff"
            readonly property color primaryBg: isDark ? "#ffffff" : "#09090b"
            readonly property color primaryText: isDark ? "#000000" : "#ffffff"
            readonly property color linkColor: isDark ? "#60a5fa" : "#3b82f6"
            readonly property color overlayBg: isDark ? "#80000000" : "#30000000"
        }
    )QML", QUrl());
    QObject* themeObj = themeComp.create();
    if (themeObj) {
        themeObj->setParent(&app);
        engine.rootContext()->setContextProperty(QStringLiteral("Theme"), themeObj);
    }

    // 2. جسر تواصل خفيف بين إشارات QML ودوال C++
    BridgeMap bridge(&app);
    bridge.insert(QStringLiteral("cmd"), QVariant(QString()));
    engine.rootContext()->setContextProperty(QStringLiteral("cppBridge"), &bridge);

    const QUrl mainQmlUrl = resolveMainQmlUrl();
    if (mainQmlUrl.isLocalFile()) {
        engine.addImportPath(QFileInfo(mainQmlUrl.toLocalFile()).absolutePath());
    } else {
        engine.addImportPath(QStringLiteral("qrc:/ui"));
        engine.addImportPath(QStringLiteral("qrc:/"));
    }

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [mainQmlUrl](QObject* obj, const QUrl& objUrl) {
            if (!obj && mainQmlUrl == objUrl) {
                std::cerr << "[Fatal] فشل تحميل واجهة QML: " << mainQmlUrl.toString().toStdString() << std::endl;
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection
    );

    engine.load(mainQmlUrl);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    g_rootObject = engine.rootObjects().first();

    // ربط إشارات QML في ui/main.qml بجسر C++ مباشرة
    QQmlExpression signalBinder(
        engine.rootContext(),
        g_rootObject,
        QStringLiteral(
            "var _seq = 0;"
            "openEpubDialog.connect(function() { cppBridge.cmd = 'open_epub:' + (++_seq); });"
            "goNextChapter.connect(function()  { cppBridge.cmd = 'next_chapter:' + (++_seq); });"
            "goPrevChapter.connect(function()  { cppBridge.cmd = 'prev_chapter:' + (++_seq); });"
            "goBackHome.connect(function()     { cppBridge.cmd = 'back_home:' + (++_seq); });"
            "goToChapter.connect(function(ch)  { cppBridge.cmd = 'goto_chapter:' + (++_seq) + ':' + ch; });"
            "openLink.connect(function(url)    { cppBridge.cmd = 'open_link:' + (++_seq) + ':' + url; });"
        )
    );
    signalBinder.evaluate();
    if (signalBinder.hasError()) {
        std::cerr << "[QML Bind Error] " << signalBinder.error().toString().toStdString() << std::endl;
    }

    // الاستجابة للأوامر القادمة من الواجهة
    QObject::connect(&bridge, &QQmlPropertyMap::valueChanged, &app, [](const QString& key, const QVariant& value) {
        if (key != QStringLiteral("cmd")) return;

        const QString raw = value.toString();
        const int firstColon = raw.indexOf(u':');
        if (firstColon < 0) return;

        const QString action = raw.left(firstColon);
        const int secondColon = raw.indexOf(u':', firstColon + 1);
        const QString payload = (secondColon >= 0) ? raw.mid(secondColon + 1) : QString();

        if (action == QStringLiteral("open_epub")) {
#if defined(__linux__) && !defined(__ANDROID__)
            bool handledByExternal = false;
            std::string filePath = openNativeLinuxFileDialog(handledByExternal);
            if (handledByExternal) {
                if (!filePath.empty()) {
                    openBookAndShow(filePath);
                }
                return;
            }
#elif defined(__ANDROID__)
            if (g_jvm && g_activity) {
                JNIEnv* env = nullptr;
                g_jvm->AttachCurrentThread(&env, nullptr);
                if (env) {
                    jclass clazz = env->GetObjectClass(g_activity);
                    jmethodID methodId = env->GetMethodID(clazz, "openFilePicker", "()V");
                    if (methodId) {
                        env->CallVoidMethod(g_activity, methodId);
                    }
                }
                return;
            }
#endif
            // Windows / macOS / أو Linux بدون zenity / أو Android قياسي
            const QString selectedFile = QFileDialog::getOpenFileName(
                nullptr,
                QStringLiteral("اختر كتاب EPUB"),
                QString(),
                QStringLiteral("EPUB Books (*.epub)")
            );

            if (!selectedFile.isEmpty()) {
                QString localPath = QUrl(selectedFile).isLocalFile()
                                        ? QUrl(selectedFile).toLocalFile()
                                        : selectedFile;
                openBookAndShow(localPath.toUtf8().constData());
            }
        }
        else if (action == QStringLiteral("next_chapter")) {
            if (g_reader->nextChapter()) {
                updateReaderUI();
            }
        }
        else if (action == QStringLiteral("prev_chapter")) {
            if (g_reader->prevChapter()) {
                updateReaderUI();
            }
        }
        else if (action == QStringLiteral("goto_chapter")) {
            int targetChapter = payload.toInt();
            const int maxChapters = g_reader->getChapterCount();
            if (maxChapters > 0) {
                if (targetChapter < 1) targetChapter = 1;
                if (targetChapter > maxChapters) targetChapter = maxChapters;
                g_reader->goToChapter(targetChapter - 1);
                updateReaderUI();
            }
        }
        else if (action == QStringLiteral("back_home")) {
            if (g_rootObject) {
                g_rootObject->setProperty("readingMode", false);
                g_rootObject->setProperty("showInfo", false);
            }
            g_reader->close();
        }
        else if (action == QStringLiteral("open_link")) {
            if (!payload.isEmpty()) {
                QDesktopServices::openUrl(QUrl(payload));
            }
        }
    });

    // أندرويد: لو وصل كتاب من "فتح بواسطة" قبل جاهزية الواجهة نفتحه الآن مباشرة
    std::string pendingPath;
    {
        std::lock_guard<std::mutex> lock(g_pendingMutex);
        g_uiReady = true;
        pendingPath.swap(g_pendingBookPath);
    }
    if (!pendingPath.empty()) {
        openBookAndShow(pendingPath);
    }

    // دعم فتح كتاب مباشرة عبر تمرير مساره في سطر الأوامر (CLI)
#ifndef __ANDROID__
    const QStringList args = app.arguments();
    if (args.size() > 1) {
        const QString cliPath = args.at(1);
        if (QFileInfo::exists(cliPath)) {
            openBookAndShow(cliPath.toUtf8().constData());
        }
    }
#endif

    return app.exec();
}