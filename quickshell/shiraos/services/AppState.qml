pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool   wallpaperOpen:  false
    property bool   islandOpen:     false
    property bool   launcherOpen:   false
    property bool   autoScheme:     true
    property bool   schemeOpen:     false

    function toggleWallpaper() { wallpaperOpen = !wallpaperOpen }
    function toggleIsland()    { islandOpen    = !islandOpen    }
    function toggleLauncher()  { launcherOpen  = !launcherOpen  }
    function toggleDockSettings() { dockSettingsOpen = !dockSettingsOpen }

    // ── Font Config ──────────────────────────────────────────
    property string globalFont: "DejaVu Sans"
    property string iconFont:   "FantasqueSansM Nerd Font"

    // ── Dock Config ───────────────────────────────────────────
    property bool   dockSettingsOpen: false
    property int    dockStyle:   0      // 0=bottom 1=left 2=bottom-left 3=bottom-full
    property var    pinnedApps:  []     // [{icon,label,cmd}]

    // ── Adaptive Color — Material 3 via matugen ───────────────
    property color accentColor:  Qt.rgba(0.29, 0.62, 1.0,  1.0)
    property color accentPill:   Qt.rgba(0.05, 0.11, 0.22, 0.65)
    property color accentBorder: Qt.rgba(0.29, 0.62, 1.0,  0.40)
    property color accentDark:   Qt.rgba(0.10, 0.08, 0.18, 0.90)
    property color accentText:   Qt.rgba(1.0,  1.0,  1.0,  0.92)
    property color surface:      Qt.rgba(0.07, 0.07, 0.09, 1.0)
    property color onSurface:    Qt.rgba(0.89, 0.88, 0.91, 1.0)
    property color outline:      Qt.rgba(0.56, 0.56, 0.60, 1.0)

    // Transições suaves ao mudar de scheme (800ms)
    Behavior on accentColor  { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on accentPill   { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on accentBorder { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on accentDark   { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on accentText   { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on surface      { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on onSurface    { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on outline      { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
}
