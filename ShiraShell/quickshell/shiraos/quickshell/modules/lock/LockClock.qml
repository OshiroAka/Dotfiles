import Quickshell.Io
import QtQuick
import QtQuick.Effects

// Tema 2: Relógio grande — hora domina a tela, senha sutil embaixo
Item {
    id: root
    signal unlock(string password)
    property bool shakeOnFail: false

    onShakeOnFailChanged: {
        if (shakeOnFail) shakeAnim.start()
    }

    // ── Hora gigante ──────────────────────────────────────
    Text {
        id: clockText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        text: Qt.formatTime(new Date(), "hh:mm")
        color: Qt.rgba(1, 1, 1, 0.15)
        font.pixelSize: parent.width * 0.30
        font.bold: true

        Timer {
            interval: 1000; repeat: true; running: true
            onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    // ── Data ──────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: passwordPill.top
        anchors.bottomMargin: 60
        text: Qt.formatDate(new Date(), "dddd, dd 'de' MMMM")
        color: Qt.rgba(1,1,1,0.6)
        font.pixelSize: 18
    }

    // ── Bateria — canto superior direito ──────────────────
    Text {
        id: batText
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.right: parent.right
        anchors.rightMargin: 40
        color: Qt.rgba(1,1,1,0.5)
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

    // ── Senha sutil embaixo ───────────────────────────────
    Rectangle {
        id: passwordPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        width: 260; height: 48
        radius: 24
        color: Qt.rgba(1, 1, 1, 0.08)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

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
            color: Qt.rgba(1,1,1,0.35)
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
            anchors.fill: parent; radius: parent.radius; color: "transparent"
            border.color: Qt.rgba(0.9, 0.3, 0.3, root.shakeOnFail ? 0.8 : 0)
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
    }
}
