pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool wallpaperOpen: false
    property bool islandOpen:    false

    function toggleWallpaper() { wallpaperOpen = !wallpaperOpen }
    function toggleIsland()    { islandOpen    = !islandOpen    }

    // ── Adaptive Color ────────────────────────────────────────────────────
    property color accentColor:  Qt.rgba(0.29, 0.62, 1.0,  1.0)
    property color accentPill:   Qt.rgba(0.05, 0.11, 0.22, 0.65)
    property color accentBorder: Qt.rgba(0.29, 0.62, 1.0,  0.40)
    property color accentDark:  Qt.rgba(0.10, 0.08, 0.18, 0.90)
    // SEM function — conversão feita inline no shell.qml

}