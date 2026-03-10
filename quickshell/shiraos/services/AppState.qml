pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool wallpaperOpen: false
    property bool islandOpen:    false

    function toggleWallpaper() { wallpaperOpen = !wallpaperOpen }
    function toggleIsland()    { islandOpen    = !islandOpen    }



    // ── Adaptive Color ────────────────────────────────────────────────────
    property color accentColor:  Qt.rgba(0.42, 0.42, 1.0,  1.0)
    property color accentPill:   Qt.rgba(0.04, 0.04, 0.08, 0.60)
    property color accentBorder: Qt.rgba(0.3,  0.3,  0.6,  0.25)



}