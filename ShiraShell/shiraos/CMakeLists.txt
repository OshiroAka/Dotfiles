cmake_minimum_required(VERSION 3.20)
project(ShiraOS)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

qt6_policy(SET QTP0001 NEW)

add_subdirectory(plugin)

# Instala o plugin .so
install(FILES
    "${CMAKE_BINARY_DIR}/plugin/libShiraOSPluginplugin.so"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS"
)

# Instala o qmldir
install(FILES
    "${CMAKE_SOURCE_DIR}/plugin/qmldir"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS"
)

# Instala QML files
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/modules/"
    DESTINATION "${QT6_INSTALL_QML}/ShiraOS/modules"
    FILES_MATCHING PATTERN "*.qml"
)
