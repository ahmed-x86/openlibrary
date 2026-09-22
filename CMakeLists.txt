cmake_minimum_required(VERSION 3.20)
project(OpenLibrary VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt requires MOC (Meta-Object Compiler) processing
set(CMAKE_AUTOMOC ON)

# ============================================================
# المكتبات الخارجية
# ============================================================
include(FetchContent)

# --- مكتبة Slint (واجهة المستخدم) ---
find_package(Slint QUIET)
if (NOT Slint_FOUND)
    FetchContent_Declare(
        Slint
        GIT_REPOSITORY https://github.com/slint-ui/slint.git
        GIT_TAG        release/1
        SOURCE_SUBDIR  api/cpp
    )

    # على x86 Android يوجد خطأ معروف في skia-bindings: أحجام الـ structs مختلفة
    # بين C++ وRust على 32-bit x86، مما يسبب compile-time assertion failures.
    # الحل: تفعيل Software Renderer وتعطيل Skia لـ x86 فقط.
    if (ANDROID AND ANDROID_ABI STREQUAL "x86")
        set(SLINT_FEATURE_RENDERER_SKIA OFF CACHE BOOL "Disable Skia renderer for x86 (ABI mismatch)" FORCE)
        set(SLINT_FEATURE_RENDERER_SOFTWARE ON CACHE BOOL "Enable software renderer for x86" FORCE)
    endif()

    FetchContent_MakeAvailable(Slint)
endif()

# --- مكتبة libzip (فك ضغط ملفات EPUB/ZIP) ---
find_package(PkgConfig QUIET)
if (PKG_CONFIG_FOUND)
    pkg_check_modules(LIBZIP QUIET IMPORTED_TARGET libzip)
endif()

if (NOT LIBZIP_FOUND)
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
    # نوقف خطوة install/export الخاصة بـ libzip لأننا نستخدمها كمكتبة ثابتة مدمجة فقط
    # ولا نحتاج تثبيتها؛ بدون هذا السطر يفشل CMake Generate لأن target "zip" يحاول
    # يصدّر export set بيحتاج target "zlibstatic" وهو غير موجود في أي export set
    # (لأننا جلبنا zlib بأنفسنا عبر FetchContent بدون تثبيته رسميًا).
    set(LIBZIP_DO_INSTALL OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(libzip)
endif()

# --- مكتبة pugixml (قراءة XML) ---
FetchContent_Declare(
    pugixml
    GIT_REPOSITORY https://github.com/zeux/pugixml.git
    GIT_TAG        v1.14
)
FetchContent_MakeAvailable(pugixml)

# --- Qt6 (بديل nativefiledialog — يستخدم QFileDialog و QDesktopServices) ---
if (NOT ANDROID)
    find_package(Qt6 COMPONENTS Core Gui Widgets REQUIRED)
endif()

# ============================================================
# الملف التنفيذي أو المكتبة (حسب النظام)
# ============================================================
if (ANDROID)
    # أندرويد يتطلب بناء C++ كمكتبة ديناميكية (Shared Library)
    add_library(openlibrary SHARED
        src/main.cpp
        src/epub_reader.cpp
    )
else()
    add_executable(openlibrary
        src/main.cpp
        src/epub_reader.cpp
    )
endif()

# تجميع ملف الواجهة (.slint) وتحويله إلى كود C++
slint_target_sources(openlibrary ui/main.slint)

# ============================================================
# إجبار Slint على دمج جميع الصور (SVGs/PNGs) مباشرة داخل التطبيق
# ============================================================
set_target_properties(openlibrary PROPERTIES SLINT_EMBED_RESOURCES embed-files)

# ربط جميع المكتبات بالمشروع
if (TARGET PkgConfig::LIBZIP)
    target_link_libraries(openlibrary PRIVATE PkgConfig::LIBZIP)
else()
    target_link_libraries(openlibrary PRIVATE zip)
endif()

target_link_libraries(openlibrary PRIVATE
    Slint::Slint
    pugixml
)

if (NOT ANDROID)
    target_link_libraries(openlibrary PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
    )
endif()

# ============================================================
# Installation
# ============================================================
if (NOT ANDROID)
    install(TARGETS openlibrary DESTINATION bin)
    if (UNIX AND NOT APPLE)
        install(FILES openlibrary.desktop DESTINATION share/applications)
        # Assuming icon will be downloaded to assets/icon.png during build
        install(FILES assets/icon.png DESTINATION share/pixmaps RENAME openlibrary.png)
    endif()
endif()

# ============================================================
# CPack Packaging
# ============================================================
set(CPACK_PACKAGE_NAME "openlibrary")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Open Source EPUB Reader")
set(CPACK_PACKAGE_CONTACT "ahmed-x86")

if (WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "
        WriteRegStr HKCR \\\\\".epub\\\\\" \\\\\"\\\\\" \\\\\"OpenLibrary.EPUB\\\\\"
        WriteRegStr HKCR \\\\\"OpenLibrary.EPUB\\\\shell\\\\open\\\\command\\\\\" \\\\\"\\\\\" \\\\\"\\\\\\\\\\\"$INSTDIR\\\\\\\\openlibrary.exe\\\\\\\\\\\" \\\\\\\\\\\\\\\"%1\\\\\\\\\\\\\\\"\\\\\"
    ")
elseif (UNIX AND NOT APPLE AND NOT ANDROID)
    set(CPACK_GENERATOR "DEB;RPM")
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "fontconfig, qt6-base-dev")
    set(CPACK_RPM_PACKAGE_REQUIRES "fontconfig, qt6-qtbase")
endif()

include(CPack)