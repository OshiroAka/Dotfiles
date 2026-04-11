cmake_minimum_required(VERSION 3.16)
project(oshiro)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED wayland-client)

execute_process(
    COMMAND qmake6 -query QT_INSTALL_HEADERS
    OUTPUT_VARIABLE QT_HEADERS OUTPUT_STRIP_TRAILING_WHITESPACE
)

add_library(oshiro SHARED
    plugin/WaylandRegion.cpp
    plugin/Plugin.cpp
)

target_link_libraries(oshiro Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick ${WAYLAND_LIBRARIES})
target_include_directories(oshiro PRIVATE ${WAYLAND_INCLUDE_DIRS} ${QT_HEADERS})

install(TARGETS oshiro DESTINATION /home/oshiro/.config/quickshell/plugin)
install(FILES plugin/qmldir DESTINATION /home/oshiro/.config/quickshell/plugin)
