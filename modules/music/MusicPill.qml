import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win

    // Sem layer/exclusiveZone por agora -- so pra testar
    anchors.top: true
    margins.top: 8
    color: "transparent"

    readonly property int collapsedW: 220
    readonly property int collapsedH: 36
    readonly property int expandedW: 400
    readonly property int expandedH: 118

    width: pill.width + 2
    height: pill.height + 2

    property MprisPlayer activePlayer: {
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i]
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    }

    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string songTitle: activePlayer?.trackTitle ?? "Nenhuma musica"
    readonly property string songArtist: activePlayer?.trackArtist ?? "-"
    readonly property string albumArt: activePlayer?.trackArtUrl ?? ""
    property real livePosition: 0
    readonly property real duration: activePlayer?.trackLength ?? 1
    property bool hovered: false
    property bool expanded: hovered && activePlayer !== null

    Rectangle {
        id: pill

        Behavior on width  { NumberAnimation { duration: 100; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutExpo } }

        width:  win.expanded ? win.expandedW : win.collapsedW
        height: win.expanded ? win.expandedH : win.collapsedH
        radius: height / 2
        color: Qt.rgba(0.08, 0.08, 0.12, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1

        HoverHandler {
            onHoveredChanged: win.hovered = hovered
        }

        // --- COLAPSADO ---
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 8
            opacity: win.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
            visible: opacity > 0

            Rectangle {
                width: 22; height: 22; radius: 11
                color: "#333"; clip: true
                Image {
                    anchors.fill: parent
                    source: win.albumArt
                    fillMode: Image.PreserveAspectCrop
                }
                Text {
                    anchors.centerIn: parent
                    text: "♪"; color: "white"; font.pixelSize: 12
                    visible: win.albumArt === ""
                }
            }

            Text {
                Layout.fillWidth: true
                text: win.songTitle
                color: "white"; font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Row {
                spacing: 2
                visible: win.isPlaying
                Repeater {
                    model: 3
                    Rectangle {
                        width: 3; color: "#ffffff"; radius: 1.5
                        height: 8
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            loops: Animation.Infinite
                            running: win.isPlaying
                            NumberAnimation { to: 14; duration: 300 + index * 80; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 5;  duration: 300 + index * 80; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        // --- EXPANDIDO ---
        Item {
            anchors.fill: parent
            anchors.margins: 14
            opacity: win.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            visible: opacity > 0

            RowLayout {
                id: topRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: 44; height: 44; radius: 8
                    color: "#222"; clip: true
                    Image {
                        anchors.fill: parent
                        source: win.albumArt
                        fillMode: Image.PreserveAspectCrop
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "♪"; color: "#888"; font.pixelSize: 20
                        visible: win.albumArt === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: win.songTitle; color: "white"
                        font.pixelSize: 14; font.weight: Font.SemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: win.songArtist
                        color: Qt.rgba(1,1,1,0.55); font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                anchors.top: topRow.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                ControlBtn { icon: "\u23ee"; onClicked: win.activePlayer?.previous() }

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: Qt.rgba(1,1,1,0.12)
                    Text {
                        anchors.centerIn: parent
                        text: win.isPlaying ? "\u23f8" : "\u25b6"
                        color: "white"; font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.activePlayer?.togglePlaying()
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                ControlBtn { icon: "\u23ed"; onClicked: win.activePlayer?.next() }
            }

            Item {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: formatTime(win.position)
                    color: Qt.rgba(1,1,1,0.4); font.pixelSize: 10
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: formatTime(win.duration)
                    color: Qt.rgba(1,1,1,0.4); font.pixelSize: 10
                }

                Item {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 30; anchors.rightMargin: 30
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4

                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(1,1,1,0.15) }
                    Rectangle {
                        width: parent.width * Math.min(win.position / win.duration, 1)
                        height: parent.height; radius: 2; color: "#e06c75"
                        Behavior on width { NumberAnimation { duration: 500 } }
                    }
                    Rectangle {
                        x: parent.width * Math.min(win.position / win.duration, 1) - 5
                        y: -3; width: 10; height: 10; radius: 5; color: "white"
                    }
                }
            }
        }
    }

    function formatTime(us) {
        var totalSeconds = Math.floor(us / 1000000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + String(seconds).padStart(2, "0")
    }

    Timer {
        interval: 1000
        running: win.isPlaying
        repeat: true

        onTriggered: {
            if (win.activePlayer)
                win.livePosition = win.activePlayer.position
        }
    }
}