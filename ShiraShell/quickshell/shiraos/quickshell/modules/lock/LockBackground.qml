import QtQuick
import QtQuick.Effects
import Quickshell.Io

// Fundo da lockscreen — suporta wallpaper estático, mpv (live) e blur
Item {
    id: root
    property bool blurEnabled: true

    // Lê o wallpaper atual do swww
    Process {
        id: wallpaperProc
        command: ["bash", "-c", "swww query | grep -o 'image:.*' | cut -d' ' -f2 | head -1"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.trim()
                if (p.length > 0) {
                    staticBg.source = "file://" + p
                    // Se for vídeo, usa mpv
                    if (p.endsWith(".mp4") || p.endsWith(".mkv") || p.endsWith(".gif") || p.endsWith(".webm")) {
                        mpvBg.visible  = true
                        staticBg.visible = false
                        mpvBg.source   = p
                    } else {
                        staticBg.visible = true
                        mpvBg.visible  = false
                    }
                }
            }
        }
    }

    // Wallpaper estático
    Image {
        id: staticBg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        visible: true
        asynchronous: true
        cache: false
        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: 1.0
            blurMax: 64
            blurMultiplier: 1.0
        }
    }

    // Wallpaper live via mpv
    Process {
        id: mpvBg
        property string source: ""
        command: ["mpv", "--no-audio", "--loop", "--no-border",
                  "--wid=" + mpvContainer.winId,
                  "--vo=gpu", source]
        running: source.length > 0 && mpvBg.visible
    }

    Rectangle {
        id: mpvContainer
        anchors.fill: parent
        color: "black"
        visible: false
        property int winId: 0

        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: 1.0
            blurMax: 64
        }
    }
}
