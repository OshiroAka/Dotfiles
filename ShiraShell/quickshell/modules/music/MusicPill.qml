import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import Quickshell.Wayland
import "../shared"
import OshiroShell 1.0

PanelWindow {
    id: win
    anchors.top: true
    anchors.left: true
    margins.top: 8
    margins.left: screen ? Math.round((screen.width - pill.width) / 2) : 560
    color: "transparent"
    implicitWidth:  pill.width
    implicitHeight: pill.height

    property MprisPlayer activePlayer: {
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i]
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    }
    readonly property bool   isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string songTitle: activePlayer?.trackTitle  ?? "Nenhuma musica"
    readonly property string albumArt:  activePlayer?.trackArtUrl ?? ""

    ColorExtractor { id: colorEx; imageSource: win.albumArt }
    readonly property color accentColor: win.albumArt !== "" ? colorEx.dominantColor : "#1DB954"

    WaylandRegion { id: region }
    Item {
        id: wb; visible: false
        Component.onCompleted: Qt.callLater(function() {
            var w = wb.Window.window
            if (w) region.apply(w, 0, 0, Math.round(pill.width), Math.round(pill.height))
        })
    }

    Item {
        id: wrapper
        anchors.fill: parent
        property bool pillVisible: true

        Connections {
            target: AppState
            function onOverlayOpenChanged() {
                if (AppState.overlayOpen) wrapper.pillVisible = false
            }
            function onCloseDone() {
                wrapper.pillVisible = true
            }
        }

        opacity: wrapper.pillVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: pill
            antialiasing: true
            width:  Math.min(Math.max(200, titleText.implicitWidth + 80), 500)
            height: 32
            radius: 16
            color:  Qt.rgba(0.06, 0.06, 0.10, 0.40)

            onWidthChanged: {
                var w = wb.Window.window
                if (w) region.apply(w, 0, 0, Math.round(width), Math.round(height))
            }

            Behavior on width {
                SmoothedAnimation { duration: 300; easing.type: Easing.InOutCubic }
            }

            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.12); border.width: 1; antialiasing: true
            }

            Rectangle {
                id: cover
                anchors.left: parent.left; anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; radius: 10
                color: "#333"; clip: true; antialiasing: true
                visible: win.albumArt !== ""
                Image {
                    anchors.fill: parent; source: win.albumArt
                    fillMode: Image.PreserveAspectCrop; smooth: true
                }
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "♪"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 13
                visible: win.albumArt === ""
            }

            Item {
                anchors.left: cover.visible ? cover.right : parent.left
                anchors.leftMargin: cover.visible ? 7 : 26
                anchors.right: eqRow.left; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: 18; clip: true

                Text {
                    id: titleText
                    text: win.songTitle
                    color: "white"; font.pixelSize: 12; font.weight: Font.Medium
                    x: 0
                    SequentialAnimation {
                        id: marqueeAnim
                        running: titleText.implicitWidth > (pill.width - 100)
                        loops: Animation.Infinite
                        PauseAnimation  { duration: 2000 }
                        NumberAnimation {
                            target: titleText; property: "x"
                            from: 0; to: -(titleText.implicitWidth + 20)
                            duration: titleText.implicitWidth * 16
                            easing.type: Easing.Linear
                        }
                        PauseAnimation  { duration: 800 }
                        NumberAnimation { target: titleText; property: "x"; to: 0; duration: 0 }
                    }
                    onTextChanged: { x = 0; marqueeAnim.restart() }
                }
            }

            Row {
                id: eqRow
                anchors.right: parent.right; anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Repeater {
                    model: 4
                    Rectangle {
                        width: 3; height: 8; radius: 1.5
                        color: win.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            loops: Animation.Infinite; running: win.isPlaying
                            NumberAnimation { to: 5+(index+1)*3; duration: 300+index*80; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 3; duration: 300+index*80; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }
    }
}
