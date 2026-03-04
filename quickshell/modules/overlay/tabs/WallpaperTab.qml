import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../shared"

Item {
    id: root

    // Carrega wallpapers da pasta
    property var wallpapers: []
    property int currentIndex: 0
    property string wallpaperDir: {
        var t = AppState.wallpaperType === "live" ? "live" : "static"
        return Qt.resolvedUrl("file://" + QS.env("HOME") + "/Pictures/Wallpapers/" + t + "/")
    }

    FileView {
        id: dirView
        path: wallpaperDir.replace("file://", "")
        onFilesChanged: {
            var imgs = []
            for (var i = 0; i < files.length; i++) {
                var f = files[i]
                if (/\.(jpg|jpeg|png|gif|mp4|webm)$/i.test(f))
                    imgs.push(wallpaperDir + f)
            }
            root.wallpapers = imgs
        }
    }

    // Navegacao por teclado
    Keys.onUpPressed:   applyWallpaper(Math.max(0, currentIndex - 1))
    Keys.onDownPressed: applyWallpaper(Math.min(wallpapers.length - 1, currentIndex + 1))
    focus: AppState.overlayOpen && AppState.activeTab === "wallpaper"

    function applyWallpaper(idx) {
        currentIndex = idx
        var path = wallpapers[idx].replace("file://", "")
        var engine = AppState.wallpaperEngine
        if (engine === "swww") {
            swwwProcess.command = ["swww", "img", path, "--transition-type", "grow", "--transition-duration", "1"]
            swwwProcess.running = true
        } else {
            mpvProcess.command = ["mpvpaper", "*", path, "--loop"]
            mpvProcess.running = true
        }
    }

    Process { id: swwwProcess; running: false }
    Process { id: mpvProcess;  running: false }

    // Carrossel
    ListView {
        anchors.fill: parent
        model: root.wallpapers
        orientation: ListView.Horizontal
        spacing: 12
        clip: true

        // Centraliza no item atual
        preferredHighlightBegin: width/2 - 160
        preferredHighlightEnd:   width/2 + 160
        highlightRangeMode: ListView.StrictlyEnforceRange
        currentIndex: root.currentIndex

        Behavior on contentX {
            SmoothedAnimation { duration: AppState.animDuration(300); easing.type: Easing.InOutCubic }
        }

        delegate: Item {
            width: 300; height: parent.height
            // Efeito de escala e escurecimento nos lados
            property bool isActive: index === root.currentIndex
            scale: isActive ? 1.0 : 0.82
            opacity: isActive ? 1.0 : 0.45

            Behavior on scale   { NumberAnimation { duration: AppState.animDuration(250); easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: AppState.animDuration(250) } }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#111"
                clip: true
                layer.enabled: true

                Image {
                    anchors.fill: parent
                    source: modelData
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                }

                // Overlay escuro nos nao selecionados
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0,0,0, isActive ? 0 : 0.35)
                    Behavior on color { ColorAnimation { duration: AppState.animDuration(250) } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyWallpaper(index)
            }
        }
    }

    // Indicador de tipo (static/live)
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Repeater {
            model: ["static", "live"]
            Rectangle {
                width: 60; height: 24; radius: 12
                color: AppState.wallpaperType === modelData ?
                    Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: 180 } }
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: AppState.wallpaperType === modelData ? "white" : Qt.rgba(1,1,1,0.4)
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppState.wallpaperType = modelData
                }
            }
        }
    }
}
