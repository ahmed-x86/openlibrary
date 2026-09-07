cmake_minimum_required(VERSION 3.20)
project(OpenLibrary VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
    FetchContent_MakeAvailable(libzip)
endif()

# --- مكتبة pugixml (قراءة XML) ---
FetchContent_Declare(
    pugixml
    GIT_REPOSITORY https://github.com/zeux/pugixml.git
    GIT_TAG        v1.14
)
FetchContent_MakeAvailable(pugixml)

# --- مكتبة nativefiledialog-extended (مدير الملفات) ---
FetchContent_Declare(
    nfd
    GIT_REPOSITORY https://github.com/btzy/nativefiledialog-extended.git
    GIT_TAG        v1.2.1
)
set(NFD_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(NFD_INSTALL OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(nfd)

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

# مكتبة nativefiledialog (nfd) لا تدعم أندرويد، فنستثنيها عند البناء له
if (NOT ANDROID)
    target_link_libraries(openlibrary PRIVATE nfd)
endif()