import Quickshell
import Quickshell.Io
import QtQuick
import "./modules/music"
import "./modules/overlay"
import "./modules/shared"

ShellRoot {
    MusicPill {}
    Overlay {}
    WallpaperOverlay {}
    MenuOverlay {}

    IpcHandler {
        target: "shell"
        function toggle(): void { AppState.toggle() }
    }
}
