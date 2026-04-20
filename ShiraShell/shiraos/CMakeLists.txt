cmake_minimum_required(VERSION 3.20)
project(ShiraOS)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

add_subdirectory(plugin)

# Instala todos os .so gerados pelo plugin
install(DIRECTORY "${CMAKE_BINARY_DIR}/plugin/"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS"
    FILES_MATCHING
        PATTERN "*.so"
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
)

# Instala QML
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/modules/"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS/modules"
    FILES_MATCHING PATTERN "*.qml"
)
