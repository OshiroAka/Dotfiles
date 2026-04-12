import Quickshell.Io
import QtQuick
import QtQuick.Effects

// Tema 1: Esquerda — hora grande à esquerda, senha à direita
Item {
    id: root
    signal unlock(string password)
    property bool shakeOnFail: false

    onShakeOnFailChanged: {
        if (shakeOnFail) shakeAnim.start()
    }

    // ── Coluna esquerda ───────────────────────────────────
    Column {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.08
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            id: clockText
            text: Qt.formatTime(new Date(), "hh:mm")
            color: "white"
            font.pixelSize: 110
            font.bold: true
            style: Text.Raised
            styleColor: Qt.rgba(0,0,0,0.4)

            Timer {
                interval: 1000; repeat: true; running: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }

        Text {
            text: Qt.formatDate(new Date(), "dddd")
            color: Qt.rgba(1,1,1,0.75)
            font.pixelSize: 22
        }

        Text {
            text: Qt.formatDate(new Date(), "dd 'de' MMMM")
            color: Qt.rgba(1,1,1,0.55)
            font.pixelSize: 18
        }

        Item { height: 20 }

        // Bateria
        Text {
            id: batText
            color: Qt.rgba(1,1,1,0.55)
            font.pixelSize: 14

            Process {
                id: batProc
                command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null"]
                running: true
                stdout: SplitParser {
                    onRead: function(line) {
                        var pct = parseInt(line.trim())
                        var icon = pct >= 80 ? "󰁹" : pct >= 50 ? "󰁾" : pct >= 20 ? "󰁼" : "󰁺"
                        batText.text = icon + "  " + pct + "%"
                    }
                }
            }
        }
    }

    // ── Coluna direita — avatar + senha ───────────────────
    Column {
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.08
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        // Avatar
        Rectangle {
            width: 90; height: 90; radius: 45
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            border.color: Qt.rgba(1,1,1,0.3)
            border.width: 2

            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: "file:///home/" + Qt.getenv("USER") + "/.face"
                fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle { width: 84; height: 84; radius: 42 }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.getenv("USER")
            color: Qt.rgba(1,1,1,0.6)
            font.pixelSize: 15
        }

        // Input pill
        Rectangle {
            id: passwordPill
            width: 240; height: 48
            radius: 24
            color: Qt.rgba(0, 0, 0, 0.4)
            border.color: Qt.rgba(1, 1, 1, 0.2)
            border.width: 1.5

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 12; duration: 60 }
                NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 12; duration: 60 }
                NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 8;  duration: 60 }
                NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 8;  duration: 60 }
                NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x;       duration: 60 }
            }

            Text {
                anchors.centerIn: parent
                text: "󰌾  senha"
                color: Qt.rgba(1,1,1,0.4)
                font.pixelSize: 14
                visible: passInput.length === 0
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: passInput.length > 0
                Repeater {
                    model: passInput.length
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "white" }
                }
            }

            TextInput {
                id: passInput
                anchors.fill: parent
                anchors.margins: 14
                echoMode: TextInput.Password
                color: "transparent"
                cursorVisible: false
                focus: true
                Keys.onReturnPressed: {
                    if (text.length > 0) {
                        root.unlock(text)
                        text = ""
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(0.9, 0.3, 0.3, root.shakeOnFail ? 0.8 : 0)
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
