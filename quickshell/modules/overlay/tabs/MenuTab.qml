import QtQuick
import Quickshell.Io
import "../../shared"

Item {
    id: root
    focus: true

    property var gifFiles: []
    property int hovGif: 0          // gif focado no grid
    property bool inConfig: false   // false=grid, true=configs
    property int configRow: 0       // 0=pixels, 1=velocidade

    property int cols: 3
    property int rows: Math.ceil(root.gifFiles.length / root.cols)
    property int curCol: hovGif % cols
    property int curRow: Math.floor(hovGif / cols)

    // Navegação
    Keys.onEscapePressed: AppState.overlayCurrentTab = ""
    Keys.onReturnPressed: {
        if (!inConfig) AppState.selectedGif = root.gifFiles[root.hovGif]
    }
    Keys.onLeftPressed: {
        if (inConfig) {
            inConfig = false
        } else {
            if (hovGif > 0) hovGif--
        }
    }
    Keys.onRightPressed: {
        if (!inConfig) {
            if (hovGif < gifFiles.length - 1) hovGif++
            else inConfig = true  // passou do último → configs
        } else {
            // Ajusta valor da config selecionada
            if (configRow === 0) AppState.gifSize = Math.min(300, AppState.gifSize + 20)
            else AppState.animSpeed = Math.min(3.0, Math.round((AppState.animSpeed + 0.1)*10)/10)
        }
    }
    Keys.onUpPressed: {
        if (!inConfig) {
            if (hovGif - cols >= 0) hovGif -= cols
        } else {
            configRow = Math.max(0, configRow - 1)
        }
    }
    Keys.onDownPressed: {
        if (!inConfig) {
            if (hovGif + cols < gifFiles.length) hovGif += cols
        } else {
            configRow = Math.min(1, configRow + 1)
        }
    }
    // Seta esquerda na config diminui valor
    Keys.onPressed: event => {
        if (inConfig && event.key === Qt.Key_Left) {
            if (configRow === 0) AppState.gifSize = Math.max(80, AppState.gifSize - 20)
            else AppState.animSpeed = Math.max(0.3, Math.round((AppState.animSpeed - 0.1)*10)/10)
            event.accepted = true
        }
    }

    Process {
        id: findGifs; running: true
        command: ["bash", "-c", "ls /home/oshiro/Pictures/gif/*.gif 2>/dev/null"]
        stdout: SplitParser { onRead: data => {
            var f = data.trim()
            if (f.length > 0) { var a = root.gifFiles.slice(); a.push(f); root.gifFiles = a }
        }}
    }

    // ── Layout principal ──
    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 0

        // ── Grid de GIFs ──
        Item {
            width: parent.width * 0.72
            height: parent.height

            Grid {
                id: gifGrid
                anchors.centerIn: parent
                columns: root.cols
                spacing: 8
                Repeater {
                    model: root.gifFiles
                    Item {
                        id: cell
                        property int idx: index
                        property bool active: root.hovGif === index && !root.inConfig
                        property bool selected: AppState.selectedGif === modelData

                        width: (gifGrid.parent.width - 40) / root.cols
                        height: width * 0.75

                        scale:   active ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent; radius: 12
                            color: Qt.rgba(0,0,0,0.3); clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                playing: true; smooth: true; asynchronous: true
                            }

                            // Overlay selecionado
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                color: "transparent"
                                border.color: cell.active ? "white"
                                            : cell.selected ? Qt.rgba(1,0.8,0,0.8)
                                            : "transparent"
                                border.width: cell.active ? 2 : cell.selected ? 2 : 0
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }

                            // Nome
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 18; radius: 0
                                color: Qt.rgba(0,0,0,0.55)
                                visible: cell.active || cell.selected
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.replace(/.*\//, "").replace(".gif","")
                                    color: "white"; font.pixelSize: 8
                                    elide: Text.ElideRight; width: parent.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Badge ✓ se selecionado
                            Rectangle {
                                anchors.top: parent.top; anchors.topMargin: 4
                                anchors.right: parent.right; anchors.rightMargin: 4
                                width: 16; height: 16; radius: 8
                                color: Qt.rgba(0.2,0.8,0.3,0.9)
                                visible: cell.selected
                                Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 9 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: { root.hovGif = index; root.inConfig = false }
                            onClicked: AppState.selectedGif = root.gifFiles[index]
                        }
                    }
                }
            }

            // Hint → configs
            Text {
                anchors.right: parent.right; anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: root.inConfig ? "white" : Qt.rgba(1,1,1,0.25)
                font.pixelSize: 20
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // Divisor
        Rectangle {
            width: 1; height: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1,1,1,0.08)
        }

        // ── Painel de configurações ──
        Item {
            width: parent.width * 0.28
            height: parent.height

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width - 24

                // Pixels
                Item {
                    width: parent.width; height: 48
                    property bool active: root.inConfig && root.configRow === 0

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: parent.active ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.top: parent.top; anchors.topMargin: 6
                        anchors.left: parent.left; anchors.leftMargin: 10
                        text: "Pixels"
                        color: parent.parent.active ? "white" : Qt.rgba(1,1,1,0.45)
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                        anchors.left: parent.left; anchors.leftMargin: 10
                        text: AppState.gifSize + "px"
                        color: "white"; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    // Mini slider visual
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.right: parent.right; anchors.rightMargin: 10
                        height: 2; radius: 1; color: Qt.rgba(1,1,1,0.1)
                        Rectangle {
                            width: parent.width * ((AppState.gifSize - 80) / 220)
                            height: parent.height; radius: parent.radius
                            color: Qt.rgba(1,1,1,0.6)
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: { root.inConfig = true; root.configRow = 0 }
                        onWheel: event => {
                            var d = event.angleDelta.y > 0 ? 20 : -20
                            AppState.gifSize = Math.min(300, Math.max(80, AppState.gifSize + d))
                        }
                    }
                }

                // Velocidade
                Item {
                    width: parent.width; height: 48
                    property bool active: root.inConfig && root.configRow === 1

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: parent.active ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.top: parent.top; anchors.topMargin: 6
                        anchors.left: parent.left; anchors.leftMargin: 10
                        text: "Velocidade"
                        color: parent.parent.active ? "white" : Qt.rgba(1,1,1,0.45)
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                        anchors.left: parent.left; anchors.leftMargin: 10
                        text: AppState.animSpeed.toFixed(1) + "x"
                        color: "white"; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.right: parent.right; anchors.rightMargin: 10
                        height: 2; radius: 1; color: Qt.rgba(1,1,1,0.1)
                        Rectangle {
                            width: parent.width * ((AppState.animSpeed - 0.3) / 2.7)
                            height: parent.height; radius: parent.radius
                            color: Qt.rgba(1,1,1,0.6)
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: { root.inConfig = true; root.configRow = 1 }
                        onWheel: event => {
                            var d = event.angleDelta.y > 0 ? 0.1 : -0.1
                            AppState.animSpeed = Math.min(3.0, Math.max(0.3, Math.round((AppState.animSpeed + d)*10)/10))
                        }
                    }
                }
            }
        }
    }
}
