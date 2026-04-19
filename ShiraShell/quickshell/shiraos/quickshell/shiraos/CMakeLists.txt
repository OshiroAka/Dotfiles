cmake_minimum_required(VERSION 3.20)
project(ShiraOS)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

add_subdirectory(plugin)

# Install QML files alongside plugin
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/modules/"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS/modules"
    FILES_MATCHING PATTERN "*.qml"
)
