cmake_minimum_required(VERSION 3.20)
project(OpenLibrary VERSION 1.25 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# كتم تحذيرات الإصدارات القديمة الصادرة من المكتبات الخارجية (مثل pugixml)
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)

# ============================================================
# المكتبات الخارجية
# ============================================================
include(FetchContent)
find_package(PkgConfig QUIET)

# --- 1. مكتبة libzip (فك ضغط ملفات EPUB/ZIP) ---
if (PKG_CONFIG_FOUND AND NOT ANDROID)
    pkg_check_modules(LIBZIP QUIET IMPORTED_TARGET libzip)
endif()

if (NOT LIBZIP_FOUND)
    if (ANDROID)
        # zlib موجودة أصلاً داخل NDK (مكتبة نظام مستقرة) فلا داعي لبنائها
        find_package(ZLIB REQUIRED)
    else()
        FetchContent_Declare(
            zlib
            GIT_REPOSITORY https://github.com/madler/zlib.git
            GIT_TAG        v1.3.1
        )
        FetchContent_MakeAvailable(zlib)
        if (TARGET zlibstatic AND NOT TARGET ZLIB::ZLIB)
            add_library(ZLIB::ZLIB ALIAS zlibstatic)
        endif()
        set(ZLIB_LIBRARY ZLIB::ZLIB CACHE INTERNAL "")
        set(ZLIB_INCLUDE_DIR "${zlib_SOURCE_DIR}" "${zlib_BINARY_DIR}" CACHE INTERNAL "")
        set(ZLIB_FOUND TRUE CACHE INTERNAL "")
    endif()

    FetchContent_Declare(
        libzip
        GIT_REPOSITORY https://github.com/nih-at/libzip.git
        GIT_TAG        v1.11.2
    )
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(BUILD_REGRESS OFF CACHE BOOL "" FORCE)
    set(ENABLE_BZIP2 OFF CACHE BOOL "" FORCE)
    set(ENABLE_LZMA OFF CACHE BOOL "" FORCE)
    set(ENABLE_ZSTD OFF CACHE BOOL "" FORCE)
    set(ENABLE_OPENSSL OFF CACHE BOOL "" FORCE)
    set(ENABLE_GNUTLS OFF CACHE BOOL "" FORCE)
    set(ENABLE_MBEDTLS OFF CACHE BOOL "" FORCE)
    set(BUILD_TOOLS OFF CACHE BOOL "" FORCE)
    set(BUILD_DOC OFF CACHE BOOL "" FORCE)
    set(LIBZIP_DO_INSTALL OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(libzip)
endif()

# --- 2. مكتبة pugixml (قراءة XML) ---
if (NOT ANDROID)
    find_package(pugixml QUIET)
    if (NOT pugixml_FOUND AND PKG_CONFIG_FOUND)
        pkg_check_modules(PUGIXML QUIET IMPORTED_TARGET pugixml)
    endif()
endif()

if (NOT pugixml_FOUND AND NOT PUGIXML_FOUND)
    FetchContent_Declare(
        pugixml
        GIT_REPOSITORY https://github.com/zeux/pugixml.git
        GIT_TAG        v1.14
    )
    FetchContent_MakeAvailable(pugixml)
endif()

# --- 3. أندرويد: لا حاجة لتوجيه CMAKE_PREFIX_PATH يدوياً ---
# يُبنى المشروع عبر qt.toolchain.cmake الخاص بكل معمارية (انظر release.yml)،
# وهو يضبط مسار Qt الصحيح و QT_HOST_PATH تلقائياً.

# --- 4. مكتبات Qt6 (للواجهة والملفات عبر جميع الأنظمة) ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2)
find_package(Qt6 QUIET COMPONENTS Svg)

# ============================================================
# الملف التنفيذي أو المكتبة (حسب النظام)
# ============================================================
set(PROJECT_SOURCES
    src/main.cpp
    src/epub_reader.cpp
    src/epub_reader.h
    ui/resources.qrc
)

if (ANDROID)
    # qt_add_executable ينتج libopenlibrary_<abi>.so بالتسمية التي يتوقعها
    # androiddeployqt ويفعّل الهدف `apk` الذي يحزّم Qt والإضافات و QML
    qt_add_executable(openlibrary \${PROJECT_SOURCES})
elseif (WIN32)
    add_executable(openlibrary WIN32 \${PROJECT_SOURCES})
else()
    add_executable(openlibrary \${PROJECT_SOURCES})
endif()

# تفعيل معالجات Qt (MOC + RCC) على مشروعنا فقط لمنع التحذيرات في المكتبات الخارجية
set_target_properties(openlibrary PROPERTIES
    AUTOMOC ON
    AUTORCC ON
)

target_include_directories(openlibrary PRIVATE src)

if (ANDROID)
    set_target_properties(openlibrary PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "\${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_PACKAGE_NAME       "com.ahmed_x86.openlibrary"
        QT_ANDROID_VERSION_NAME       "\${PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE       125
        QT_ANDROID_MIN_SDK_VERSION    24
        QT_ANDROID_TARGET_SDK_VERSION 34
        # ليفحص androiddeployqt ملفات QML ويضمّن QtQuick.Controls وبقية الوحدات
        QT_QML_ROOT_PATH              "\${CMAKE_CURRENT_SOURCE_DIR}/ui"
    )
endif()

# ربط مكتبة libzip
if (TARGET PkgConfig::LIBZIP)
    target_link_libraries(openlibrary PRIVATE PkgConfig::LIBZIP)
else()
    target_link_libraries(openlibrary PRIVATE zip)
endif()

# ربط مكتبة pugixml
if (TARGET pugixml::pugixml)
    target_link_libraries(openlibrary PRIVATE pugixml::pugixml)
elseif (TARGET PkgConfig::PUGIXML)
    target_link_libraries(openlibrary PRIVATE PkgConfig::PUGIXML)
else()
    target_link_libraries(openlibrary PRIVATE pugixml)
endif()

# ربط مكتبات Qt6
target_link_libraries(openlibrary PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

if (TARGET Qt6::Svg)
    target_link_libraries(openlibrary PRIVATE Qt6::Svg)
endif()

# ============================================================
# التثبيت (Installation) وإعدادات "افتح باستخدام"
# ============================================================
if (NOT ANDROID)
    install(TARGETS openlibrary DESTINATION bin)
    if (UNIX AND NOT APPLE)
        install(FILES openlibrary.desktop DESTINATION share/applications)
        if (EXISTS "\${CMAKE_CURRENT_SOURCE_DIR}/assets/icon.png")
            install(FILES assets/icon.png DESTINATION share/pixmaps RENAME openlibrary.png)
        endif()

        # تعريف نوع ملف EPUB لنظام لينكس ليظهر البرنامج في قائمة "افتح باستخدام"
        set(MIME_FILE "\${CMAKE_CURRENT_BINARY_DIR}/openlibrary-epub.xml")
        file(WRITE "\${MIME_FILE}"
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<mime-info xmlns=\"http://www.freedesktop.org/standards/shared-mime-info\">
  <mime-type type=\"application/epub+zip\">
    <comment>EPUB Electronic Book</comment>
    <glob pattern=\"*.epub\"/>
  </mime-type>
</mime-info>
")
        install(FILES "\${MIME_FILE}" DESTINATION share/mime/packages)
    endif()
endif()

# ============================================================
# التحزيم (CPack Packaging)
# ============================================================
set(CPACK_PACKAGE_NAME "openlibrary")
set(CPACK_PACKAGE_VERSION "1.25")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Open Source EPUB Reader")
set(CPACK_PACKAGE_CONTACT "ahmed-x86")

if (WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    # تسجيل البرنامج في ويندوز كمعالج افتراضي وفي قائمة "Open With" لملفات .epub فقط
    set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "
        WriteRegStr HKCR \\\".epub\\\" \\\"\\\" \\\"OpenLibrary.EPUB\\\"
        WriteRegStr HKCR \\\".epub\\\\OpenWithProgids\\\" \\\"OpenLibrary.EPUB\\\" \\\"\\\"
        WriteRegStr HKCR \\\"OpenLibrary.EPUB\\\" \\\"\\\" \\\"EPUB eBook\\\"
        WriteRegStr HKCR \\\"OpenLibrary.EPUB\\\\DefaultIcon\\\" \\\"\\\" \\\"\\\\\\\"\$INSTDIR\\\\openlibrary.exe\\\\\\\",0\\\"
        WriteRegStr HKCR \\\"OpenLibrary.EPUB\\\\shell\\\\open\\\\command\\\" \\\"\\\" \\\"\\\\\\\"\$INSTDIR\\\\openlibrary.exe\\\\\\\" \\\\\\\"%1\\\\\\\"\\\"
        WriteRegStr HKCR \\\"Applications\\\\openlibrary.exe\\\\SupportedTypes\\\" \\\".epub\\\" \\\"\\\"
        WriteRegStr HKCR \\\"Applications\\\\openlibrary.exe\\\\shell\\\\open\\\\command\\\" \\\"\\\" \\\"\\\\\\\"\$INSTDIR\\\\openlibrary.exe\\\\\\\" \\\\\\\"%1\\\\\\\"\\\"
        System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
    ")
    set(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "
        DeleteRegValue HKCR \\\".epub\\\\OpenWithProgids\\\" \\\"OpenLibrary.EPUB\\\"
        DeleteRegKey HKCR \\\"OpenLibrary.EPUB\\\"
        DeleteRegKey HKCR \\\"Applications\\\\openlibrary.exe\\\"
        System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
    ")
elseif (UNIX AND NOT APPLE AND NOT ANDROID)
    set(CPACK_GENERATOR "DEB;RPM")
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "fontconfig, libqt6core6, libqt6gui6, libqt6widgets6, libqt6qml6, libqt6quick6, libqt6svg6, shared-mime-info, desktop-file-utils")
    set(CPACK_RPM_PACKAGE_REQUIRES "fontconfig, qt6-qtbase, qt6-qtdeclarative, qt6-qtsvg, shared-mime-info, desktop-file-utils")

    # سكربتات ما بعد التثبيت والحذف لتحديث قائمة البرامج وروابط الملفات تلقائياً
    set(POSTINST_SCRIPT "\${CMAKE_CURRENT_BINARY_DIR}/postinst")
    set(POSTRM_SCRIPT "\${CMAKE_CURRENT_BINARY_DIR}/postrm")

    file(WRITE "\${POSTINST_SCRIPT}"
"#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database /usr/share/mime || true
fi
exit 0
")
    file(WRITE "\${POSTRM_SCRIPT}"
"#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database /usr/share/mime || true
fi
exit 0
")
    execute_process(COMMAND chmod 755 "${POSTINST_SCRIPT}" "${POSTRM_SCRIPT}")
    set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${POSTINST_SCRIPT};${POSTRM_SCRIPT}")
endif()

include(CPack)