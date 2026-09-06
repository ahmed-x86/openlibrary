cmake_minimum_required(VERSION 3.20)
project(OpenLibrary VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================
# المكتبات الخارجية
# ============================================================
include(FetchContent)

# --- مكتبة Slint (واجهة المستخدم) ---
find_package(Slint REQUIRED)

# --- مكتبة libzip (فك ضغط ملفات EPUB/ZIP) ---
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBZIP REQUIRED IMPORTED_TARGET libzip)

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
# الملف التنفيذي
# ============================================================
add_executable(openlibrary
    src/main.cpp
    src/epub_reader.cpp
)

# تجميع ملف الواجهة (.slint) وتحويله إلى كود C++
slint_target_sources(openlibrary ui/main.slint)

# ربط جميع المكتبات بالمشروع
target_link_libraries(openlibrary PRIVATE
    Slint::Slint
    PkgConfig::LIBZIP
    pugixml
    nfd
)