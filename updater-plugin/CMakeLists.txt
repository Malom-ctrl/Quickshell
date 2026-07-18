cmake_minimum_required(VERSION 3.16)
project(SystemUpdaterPlugin VERSION 1.0 LANGUAGES CXX)

if (POLICY QTP0001)
    cmake_policy(SET QTP0001 NEW)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml DBus)
find_package(PkgConfig REQUIRED)

# Find Flatpak and GLib
pkg_check_modules(FLATPAK REQUIRED flatpak glib-2.0)

# Create the QML Plugin
qt_add_qml_module(SystemUpdaterPlugin
    URI Custom.SystemUpdater
    VERSION 1.0
    OUTPUT_DIRECTORY Custom/SystemUpdater
    SOURCES
        FlatpakManager.hpp FlatpakManager.cpp
        OstreeUpdater.hpp OstreeUpdater.cpp
)

target_link_libraries(SystemUpdaterPlugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::DBus
    ${FLATPAK_LIBRARIES}
)

target_include_directories(SystemUpdaterPlugin PRIVATE
    ${FLATPAK_INCLUDE_DIRS}
)

target_compile_definitions(SystemUpdaterPlugin PRIVATE QT_NO_KEYWORDS)
