cmake_minimum_required(VERSION 3.20)
project(ShiraOSPlugin)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

qt_add_qml_module(ShiraOSPlugin
    URI ShiraOS
    VERSION 1.0
    SOURCES
        AppState.hpp
        plugin.cpp
)

target_link_libraries(ShiraOSPlugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
)
