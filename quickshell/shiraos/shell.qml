import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland._GlobalShortcuts
import QtQuick
import ShiraOS
import "./modules/wallpaper"
import "./modules/island"
import "./modules/border"

ShellRoot {
    IpcHandler {
        target: "shiraos"
        function toggleWallpaper() { AppState.toggleWallpaper() }
        function toggleIsland()    { AppState.toggleIsland()    }    }

    GlobalShortcut {
        name: "toggleWallpaper"
        description: "Toggle wallpaper panel"
        onPressed: AppState.toggleWallpaper()
    }
    GlobalShortcut {
        name: "wallpaperLeft"
        description: "Wallpaper category left"
        onPressed: AppState.wallpaperLeft()
    }
    GlobalShortcut {
        name: "wallpaperRight"
        description: "Wallpaper category right"
        onPressed: AppState.wallpaperRight()
    }
    GlobalShortcut {
        name: "wallpaperUp"
        description: "Wallpaper select up"
        onPressed: AppState.wallpaperUp()
    }
    GlobalShortcut {
        name: "wallpaperDown"
        description: "Wallpaper select down"
        onPressed: AppState.wallpaperDown()
    }
    LeftBorder {}
    WallpaperPanel {}
    DynamicIsland {}
    IslandExpanded {}

    // ── Adaptive Color — idêntico ao WallpaperPanel (gc1/gc2) ────────────
    Process {
        id: accentProc
        running: false
        property int lc: 0
        command: ["/home/oshiro/.local/bin/shiraos-accent-convert"]
        stdout: SplitParser {
            onRead: function(data) {
                var p = data.trim().split(" ")
                if (p.length < 3) return
                var r = Math.min(parseFloat(p[0]) * 0.8, 0.45)
                var g = Math.min(parseFloat(p[1]) * 0.8, 0.45)
                var b = Math.min(parseFloat(p[2]) * 0.8, 0.45)
                if (accentProc.lc === 0) {
                    // gc1 — igual WallpaperPanel linha 1
                    AppState.accentColor  = Qt.rgba(r, g, b, 1.0)
                    AppState.accentPill   = Qt.rgba(r, g, b, 0.30)
                    AppState.accentBorder = Qt.rgba(r, g, b, 0.18)
                } else if (accentProc.lc === 1) {
                    // gc2 — igual WallpaperPanel linha 2 (fundo escuro)
                    AppState.accentDark = Qt.rgba(r, g, b, 0.90)
                }
                accentProc.lc++
            }
        }
        onExited: function(code, status) { running = false }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            accentProc.lc = 0
            accentProc.running = false
            accentProc.running = true
        }
    }

}
