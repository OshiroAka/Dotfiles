import QtQuick
import QtQuick.Effects
import Quickshell.Io

Item {
    id: root
    signal unlock(string password)
    property bool shakeOnFail: false

    onShakeOnFailChanged: {
        if (shakeOnFail) shakeAnim.start()
    }

    Text {
        id: clockText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.18
        text: Qt.formatTime(new Date(), "hh:mm")
        color: "white"
        font.pixelSize: 96
        font.bold: true
        Timer {
            interval: 1000; repeat: true; running: true
            onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockText.bottom
        anchors.topMargin: 8
        text: Qt.formatDate(new Date(), "dddd, dd 'de' MMMM")
        color: Qt.rgba(1,1,1,0.7)
        font.pixelSize: 20
    }

    Text {
        id: batteryText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockText.bottom
        anchors.topMargin: 40
        color: Qt.rgba(1,1,1,0.55)
        font.pixelSize: 14

        Process {
            id: batProc
            command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var pct = parseInt(line.trim())
                    var icon = pct >= 90 ? "\u{f0079}" : pct >= 50 ? "\u{f007e}" : "\u{f007a}"
                    batteryText.text = icon + " " + pct + "%"
                }
            }
        }

        Timer {
            interval: 60000
            repeat: true
            running: true
            onTriggered: {
                batProc.running = false
                batProc.running = true
            }
        }
    }

    Rectangle {
        id: avatarWrapper
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        width: 96; height: 96
        radius: 48
        color: "transparent"
        border.color: Qt.rgba(1,1,1,0.3)
        border.width: 3

        Image {
            anchors.fill: parent
            anchors.margins: 3
            source: "file://" + StandardPaths.home + "/.face"
            fillMode: Image.PreserveAspectCrop
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: avatarWrapper.bottom
        anchors.topMargin: 14
        text: "Bem-vindo de volta"
        color: Qt.rgba(1,1,1,0.5)
        font.pixelSize: 14
    }

    Rectangle {
        id: passwordPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.22
        width: 280; height: 52
        radius: 26
        color: Qt.rgba(0, 0, 0, 0.35)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1.5

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 12; duration: 60 }
            NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 12; duration: 60 }
            NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 8;  duration: 60 }
            NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 8;  duration: 60 }
            NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x;      duration: 60 }
        }

        Text {
            anchors.centerIn: parent
            text: passInput.length > 0 ? "" : "senha"
            color: Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize: 15
        }

        Row {
            anchors.centerIn: parent
            spacing: 10
            visible: passInput.length > 0
            Repeater {
                model: passInput.length
                Rectangle { width: 8; height: 8; radius: 4; color: "white" }
            }
        }

        TextInput {
            id: passInput
            anchors.fill: parent
            anchors.margins: 16
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
            border.color: root.shakeOnFail ? Qt.rgba(0.9, 0.3, 0.3, 0.8) : "transparent"
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
    }
}
