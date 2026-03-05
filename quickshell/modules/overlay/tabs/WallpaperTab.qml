import QtQuick
import Quickshell.Io

Item {
    id: root

    property var wallpapers: []
    property int currentIndex: 0

    // Carrega wallpapers da pasta
    FileView {
        id: dirView
        path: (QS.env("HOME") ?? "/root") + "/Pictures/Wallpapers/static"
        onFilesChanged: {
            var imgs = []
            for (var i = 0; i < files.length; i++) {
                var f = files[i]
                if (/\.(jpg|jpeg|png|webp)$/i.test(f))
                    imgs.push(path + "/" + f)
            }
            root.wallpapers = imgs
            if (imgs.length > 0) root.currentIndex = 0
        }
    }

    // Aplica wallpaper via swww
    Process {
        id: applyProc
        running: false
    }

    function applyWallpaper(idx) {
        if (idx < 0 || idx >= wallpapers.length) return
        currentIndex = idx
        applyProc.command = ["swww", "img", wallpapers[idx],
            "--transition-type", "grow",
            "--transition-duration", "1"]
        applyProc.running = true
    }

    // Navegacao por teclado
    Keys.onLeftPressed:  root.applyWallpaper(Math.max(0, currentIndex - 1))
    Keys.onRightPressed: root.applyWallpaper(Math.min(wallpapers.length - 1, currentIndex + 1))
    focus: true

    // Placeholder se pasta vazia
    Text {
        anchors.centerIn: parent
        text: wallpapers.length === 0 ?
            "Adicione imagens em\n~/Pictures/Wallpapers/static/" :
            ""
        color: Qt.rgba(1,1,1,0.3)
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }

    // Carrossel
    ListView {
        id: carousel
        anchors.fill: parent
        anchors.margins: 12
        model: root.wallpapers
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        interactive: true

        preferredHighlightBegin: width / 2 - 130
        preferredHighlightEnd:   width / 2 + 130
        highlightRangeMode: ListView.StrictlyEnforceRange
        currentIndex: root.currentIndex

        Behavior on contentX {
            SmoothedAnimation { duration: 300; easing.type: Easing.InOutCubic }
        }

        delegate: Item {
            width: 200; height: carousel.height
            property bool active: index === root.currentIndex

            scale:   active ? 1.0 : 0.80
            opacity: active ? 1.0 : 0.45

            Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 12
                color: "#111"
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                }

                // Borda no ativo
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: parent.parent.active ?
                        Qt.rgba(1,1,1,0.5) : Qt.rgba(1,1,1,0.1)
                    border.width: parent.parent.active ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyWallpaper(index)
            }
        }
    }
}
