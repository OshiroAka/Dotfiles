pragma Singleton
import QtQuick
QtObject {
    id: root
    property bool   wallpaperOpen:  false
    property bool   islandOpen:     false
    property bool   launcherOpen:   false
    function toggleWallpaper() { wallpaperOpen = !wallpaperOpen }
    function toggleIsland()    { islandOpen    = !islandOpen    }
    function toggleLauncher()  { launcherOpen  = !launcherOpen  }
    // ── Adaptive Color ────────────────────────────────────────
    property color accentColor:  Qt.rgba(0.29, 0.62, 1.0,  1.0)
    property color accentPill:   Qt.rgba(0.05, 0.11, 0.22, 0.65)
    property color accentBorder: Qt.rgba(0.29, 0.62, 1.0,  0.40)
    property color accentDark:   Qt.rgba(0.10, 0.08, 0.18, 0.90)
}