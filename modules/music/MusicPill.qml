import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

PanelWindow {
    id: win
    anchors.top: true
    margins.top: 8
    color: "transparent"

    readonly property int collapsedW: 220
    readonly property int collapsedH: 36
    readonly property int expandedW:  480
    readonly property int expandedH:  140
    implicitWidth:  pill.width + 2
    implicitHeight: pill.height + 2

    property MprisPlayer activePlayer: {
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i]
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    }

    readonly property bool   isPlaying:  activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string songTitle:  activePlayer?.trackTitle  ?? "Nenhuma musica"
    readonly property string songArtist: activePlayer?.trackArtist ?? "-"
    readonly property string albumArt:   activePlayer?.trackArtUrl ?? ""
    readonly property string playerName: {
        if (!activePlayer) return ""
        var id = (activePlayer.identity ?? "").toLowerCase()
        if (id.includes("discord")) return "discord"
        return "spotify"
    }

    property real livePosition: 0
    readonly property real duration: {
        if (!activePlayer || activePlayer.trackLength <= 0) return 1
        return activePlayer.trackLength * 1000
    }
    property bool expanded: false

    Process { id: launchSpotify; command: ["spotify"] }
    Process { id: launchDiscord; command: ["discord"] }

    Timer {
        interval: 1000
        running: win.isPlaying
        repeat: true
        onTriggered: { if (win.activePlayer) win.livePosition = win.activePlayer.position }
    }

    ColorExtractor {
        id: colorEx
        imageSource: win.albumArt
    }

    readonly property color eqColor: {
        if (win.albumArt !== "") return colorEx.dominantColor
        if (win.playerName === "discord") return "#5865F2"
        return "#1DB954"
    }

    Rectangle {
        id: pill
        clip: true
        antialiasing: true
        color: "transparent"

        state: win.expanded ? "expanded" : "collapsed"

        states: [
            State {
                name: "collapsed"
                PropertyChanges { target: pill; width: win.collapsedW; height: win.collapsedH; radius: win.collapsedH / 2 }
                PropertyChanges { target: collapsedContent; opacity: 1 }
                PropertyChanges { target: expandedContent;  opacity: 0 }
            },
            State {
                name: "expanded"
                PropertyChanges { target: pill; width: win.expandedW; height: win.expandedH; radius: 34 }
                PropertyChanges { target: collapsedContent; opacity: 0 }
                PropertyChanges { target: expandedContent;  opacity: 1 }
            }
        ]

        transitions: [
            Transition {
                from: "collapsed"; to: "expanded"
                SequentialAnimation {
                    NumberAnimation { target: collapsedContent; property: "opacity"; duration: 80;  to: 0; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: pill; property: "height"; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 4 }
                    NumberAnimation { target: pill; property: "width";  duration: 420; easing.type: Easing.OutBack; easing.overshoot: 5 }
                    NumberAnimation { target: expandedContent;  property: "opacity"; duration: 200; to: 1; easing.type: Easing.InOutCubic }
                }
            },
            Transition {
                from: "expanded"; to: "collapsed"
                SequentialAnimation {
                    NumberAnimation { target: expandedContent;  property: "opacity"; duration: 80;  to: 0; easing.type: Easing.InOutCubic }
                    ParallelAnimation {
                        NumberAnimation { target: pill; property: "height"; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2 }
                        NumberAnimation { target: pill; property: "width";  duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
                    }
                    NumberAnimation { target: collapsedContent; property: "opacity"; duration: 200; to: 1; easing.type: Easing.InOutCubic }
                }
            }
        ]

        MouseArea {
            anchors.fill: parent
            onClicked: win.expanded = !win.expanded
            cursorShape: Qt.PointingHandCursor
            z: 0
        }

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: Qt.rgba(0.08, 0.08, 0.12, 0.35)
            antialiasing: true
            z: 1
        }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            z: 2
        }

        // ═══════════════════════════════════════════
        // COLAPSADO
        // ═══════════════════════════════════════════
        Item {
            id: collapsedContent
            anchors.fill: parent
            anchors.margins: 15
            opacity: 1
            z: 3

            Rectangle {
                id: coverCollapsed
                width: 22; height: 22; radius: 11
                color: "#333"; clip: true; antialiasing: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    anchors.fill: parent; source: win.albumArt
                    fillMode: Image.PreserveAspectCrop; visible: win.albumArt !== ""
                }
                Text {
                    anchors.centerIn: parent; text: "♪"; color: "white"
                    font.pixelSize: 12; visible: win.albumArt === ""
                }
            }

            Item {
                anchors.left: coverCollapsed.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - coverCollapsed.width - 8 - 30
                height: 20
                clip: true
                Text {
                    id: marqueeText
                    text: win.songTitle
                    color: "white"; font.pixelSize: 13; font.weight: Font.Medium
                    x: 0
                    SequentialAnimation {
                        id: marqueeAnim
                        running: !win.expanded && marqueeText.width > (pill.width - coverCollapsed.width - 70)
                        loops: Animation.Infinite
                        PauseAnimation  { duration: 1500 }
                        NumberAnimation { target: marqueeText; property: "x"; from: 0; to: -(marqueeText.width + 20); duration: marqueeText.width * 18; easing.type: Easing.Linear }
                        PauseAnimation  { duration: 800 }
                        NumberAnimation { target: marqueeText; property: "x"; to: 0; duration: 0 }
                    }
                    onTextChanged: { x = 0; marqueeAnim.restart() }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                opacity: win.isPlaying ? 1 : 0
                Repeater {
                    model: 4
                    Rectangle {
                        width: 3; height: 8; radius: 1.5
                        color: win.eqColor
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            loops: Animation.Infinite
                            running: win.isPlaying && !win.expanded
                            NumberAnimation { to: 14; duration: 450 + index * 130; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 4;  duration: 450 + index * 130; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // EXPANDIDO
        // ═══════════════════════════════════════════
        Item {
            id: expandedContent
            anchors.fill: parent
            opacity: 0
            z: 4

            // DIREITA: Album colado na borda, altura total
            Rectangle {
                id: albumRight
                width: height
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 28
                color: "#222"; clip: true; antialiasing: true
                // Arredonda só os cantos direitos
                layer.enabled: true
                Image {
                    anchors.fill: parent; source: win.albumArt
                    fillMode: Image.PreserveAspectCrop; visible: win.albumArt !== ""
                }
                Text {
                    anchors.centerIn: parent; text: "♪"
                    color: "white"; font.pixelSize: 32; visible: win.albumArt === ""
                }

            }

            // ESQUERDA cima: Visualizer
            Canvas {
                id: visualizer
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.right: albumRight.left
                anchors.rightMargin: 12
                height: 55
                property real phase: 0

                Timer {
                    interval: 32
                    running: win.isPlaying && win.expanded
                    repeat: true
                    onTriggered: { visualizer.phase += 0.12; visualizer.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    for (var w = 0; w < 3; w++) {
                        ctx.beginPath()
                        ctx.strokeStyle = Qt.rgba(win.eqColor.r, win.eqColor.g, win.eqColor.b, 0.3 + w * 0.28)
                        ctx.lineWidth = 1.5
                        ctx.shadowColor = Qt.rgba(win.eqColor.r, win.eqColor.g, win.eqColor.b, 0.5)
                        ctx.shadowBlur  = 5
                        var amp   = 12 - w * 3
                        var freq  = 0.05 + w * 0.02
                        var shift = phase + w * 1.1
                        for (var x = 0; x <= width; x += 2) {
                            var y = height/2
                                + Math.sin(x * freq + shift) * amp
                                + Math.sin(x * freq * 1.7 + shift * 0.8) * (amp * 0.4)
                            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.stroke()
                    }
                }
            }

            // ESQUERDA baixo: Título + artista
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: albumRight.left
                anchors.rightMargin: 12
                anchors.top: visualizer.bottom
                anchors.topMargin: 6
                spacing: 2

                Text {
                    width: parent.width
                    text: win.songTitle
                    color: "white"; font.pixelSize: 13; font.weight: Font.SemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: win.songArtist
                    color: Qt.rgba(1,1,1,0.5); font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // BAIXO: controles centralizados na area esquerda
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.left: parent.left
                anchors.right: albumRight.left
                spacing: 18
                layoutDirection: Qt.LeftToRight

                Item { width: (parent.width - 26 - 32 - 26 - 36) / 2; height: 1 }

                Item {
                    width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
                    opacity: prevArea.containsMouse ? 1.0 : 0.55
                    scale:   prevArea.pressed ? 0.85 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on scale   { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Image { anchors.centerIn: parent; width: 20; height: 20; source: "../../icons/rewind.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
                    MouseArea { id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: win.expanded; onClicked: win.activePlayer?.previous() }
                }

                Item {
                    width: 32; height: 32; anchors.verticalCenter: parent.verticalCenter
                    opacity: playArea.containsMouse ? 1.0 : 0.8
                    scale:   playArea.pressed ? 0.88 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on scale   { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Image { anchors.centerIn: parent; width: 26; height: 26; source: win.isPlaying ? "../../icons/pause.svg" : "../../icons/fast-forward.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
                    MouseArea { id: playArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: win.expanded; onClicked: win.activePlayer?.togglePlaying() }
                }

                Item {
                    width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
                    opacity: nextArea.containsMouse ? 1.0 : 0.55
                    scale:   nextArea.pressed ? 0.85 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on scale   { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Image { anchors.centerIn: parent; width: 20; height: 20; source: "../../icons/skip-forward.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
                    MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: win.expanded; onClicked: win.activePlayer?.next() }
                }

                // Spotify girando
                Item {
                    width: 34; height: 34; anchors.verticalCenter: parent.verticalCenter

                    NumberAnimation on rotation {
                        from: 0; to: 360; duration: 4000
                        loops: Animation.Infinite
                        running: win.isPlaying && win.expanded
                        easing.type: Easing.Linear
                    }

                    AppIcon {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        iconSource: "../../icons/spotify.svg"
                        bgColor: "#1DB954"
                        pulsing: false
                        enabled: win.expanded
                        onClicked: launchSpotify.running = true
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
}
}
