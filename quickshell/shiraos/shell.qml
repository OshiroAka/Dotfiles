import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland._GlobalShortcuts
import QtQuick
import ShiraOS
import "./modules/wallpaper"
import "./modules/island"

ShellRoot {
    IpcHandler {
        target: "shiraos"
        function toggleWallpaper() { AppState.toggleWallpaper() }
        function toggleIsland()    { AppState.toggleIsland()    }
    }

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

    WallpaperPanel {}
    DynamicIsland {}
    IslandExpanded {}

    // ── Adaptive Color ────────────────────────────────────────────────────
    Process {
        id: accentProc
        command: ["/bin/bash", "-c", "/home/oshiro/.local/bin/shiraos-accent"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var hex = line.replace("accent: #","").trim().replace("#","")
                if (hex.length !== 6) return
                var r = parseInt(hex.slice(0,2),16)/255
                var g = parseInt(hex.slice(2,4),16)/255
                var b = parseInt(hex.slice(4,6),16)/255
                AppState.accentColor  = Qt.rgba(r, g, b, 1.0)
                AppState.accentPill   = Qt.rgba(r*0.18+0.03, g*0.18+0.03, b*0.22+0.05, 0.62)
                AppState.accentBorder = Qt.rgba(r*0.55, g*0.55, b*0.55, 0.30)
            }
        }
    }

    Timer {
        interval: 4000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: accentProc.running = true
    }

}