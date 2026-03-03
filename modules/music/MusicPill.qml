import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    anchors.top: true
    margins.top: 8
    color: Qt.rgba(0, 0, 0, 0.01)
    readonly property int collapsedW: 220
    readonly property int collapsedH: 36
    readonly property int expandedW: 420
    readonly property int expandedH: 118
    implicitWidth:  pill.width + 2
    implicitHeight: pill.height + 2

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

    // Processos para abrir apps
    Process {
        id: launchSpotify
        command: ["spotify"]
    }
    Process {
        id: launchDiscord
        command: ["discord"]
    }

    Timer {
        interval: 1000
        running: win.isPlaying
        repeat: true
        onTriggered: { if (win.activePlayer) win.livePosition = win.activePlayer.position }
    }

    Rectangle {
        id: pill
        clip: true
        antialiasing: true
        width:  win.expanded ? win.expandedW : win.collapsedW
        height: win.expanded ? win.expandedH : win.collapsedH
        radius: win.expanded ? 34 : height / 2
        color: "transparent"
        Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        MouseArea {
            anchors.fill: parent
            onClicked: win.expanded = !win.expanded
            cursorShape: Qt.PointingHandCursor
        }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: Qt.rgba(0.08, 0.08, 0.12, 0.85); antialiasing: true
        }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
        }

        Item {
            anchors.fill: parent
            anchors.margins: 10

            // Capa
            Rectangle {
                id: cover
                width:  win.expanded ? 44 : 22
                height: win.expanded ? 44 : 22
                radius: win.expanded ? 8 : 11
                color: "#333"; clip: true; antialiasing: true
                anchors.left: parent.left
                anchors.top: win.expanded ? parent.top : undefined
                anchors.verticalCenter: win.expanded ? undefined : parent.verticalCenter
                Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                Image {
                    anchors.fill: parent; source: win.albumArt
                    fillMode: Image.PreserveAspectCrop; visible: win.albumArt !== ""
                }
                Text {
                    anchors.centerIn: parent; text: "♪"; color: "white"
                    font.pixelSize: win.expanded ? 20 : 12; visible: win.albumArt === ""
                }
            }

            // Titulo + artista (expandido)
            Column {
                anchors.left: cover.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 3
                visible: win.expanded
                opacity: win.expanded ? 1 : 0
                Text {
                    width: parent.width
                    text: win.songTitle
                    color: "white"; font.pixelSize: 14; font.weight: Font.SemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: win.songArtist
                    color: Qt.rgba(1,1,1,0.55); font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // Titulo rolante (colapsado)
            Item {
                anchors.left: cover.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - cover.width - 8 - 30
                height: 20
                clip: true
                visible: !win.expanded
                opacity: win.expanded ? 0 : 1
                Text {
                    id: marqueeText
                    text: win.songTitle
                    color: "white"; font.pixelSize: 13; font.weight: Font.Medium
                    x: 0
                    SequentialAnimation {
                        id: marqueeAnim
                        running: !win.expanded && marqueeText.width > (pill.width - cover.width - 70)
                        loops: Animation.Infinite
                        PauseAnimation  { duration: 1500 }
                        NumberAnimation { target: marqueeText; property: "x"; from: 0; to: -(marqueeText.width + 20); duration: marqueeText.width * 18; easing.type: Easing.Linear }
                        PauseAnimation  { duration: 800 }
                        NumberAnimation { target: marqueeText; property: "x"; to: 0; duration: 0 }
                    }
                    onTextChanged: { x = 0; marqueeAnim.restart() }
                }
            }

            // Equalizer colapsado
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                opacity: (!win.expanded && win.isPlaying) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Repeater {
                    model: 4
                    Rectangle {
                        width: 3; height: 8; radius: 1.5; color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            loops: Animation.Infinite
                            running: win.isPlaying && !win.expanded
                            NumberAnimation { to: 14; duration: 250 + index * 90; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 4;  duration: 250 + index * 90; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // ── LINHA DE BAIXO ──────────────────────────────────
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                visible: win.expanded
                opacity: win.expanded ? 1 : 0

                // Equalizer expandido
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 3; radius: 1.5; height: 8
                            color: win.playerName === "discord" ? "#5865F2" : "#1DB954"
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                running: win.isPlaying && win.expanded
                                NumberAnimation { to: 16; duration: 250 + index * 90; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 4;  duration: 250 + index * 90; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                // Spotify (componente isolado)
                AppIcon {
                    iconSource: "../../icons/spotify.svg"
                    bgColor: "#1DB954"
                    pulsing: win.isPlaying && win.expanded && win.playerName === "spotify"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: launchSpotify.running = true
                }

                // Discord (componente isolado)
                AppIcon {
                    iconSource: "../../icons/discord.svg"
                    bgColor: "#5865F2"
                    pulsing: win.isPlaying && win.expanded && win.playerName === "discord"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: launchDiscord.running = true
                }

                // Anterior
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: prevArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    scale: prevArea.pressed ? 0.85 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }
                    Text {
                        anchors.centerIn: parent; text: "⏮"
                        color: prevArea.containsMouse ? "white" : Qt.rgba(1,1,1,0.65)
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: prevArea; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.activePlayer?.previous()
                    }
                }

                // Play/Pause
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: playArea.containsMouse ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.15)
                    anchors.verticalCenter: parent.verticalCenter
                    scale: playArea.pressed ? 0.88 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }
                    Text {
                        anchors.centerIn: parent
                        text: win.isPlaying ? "⏸" : "▶"
                        color: "white"; font.pixelSize: 16
                    }
                    MouseArea {
                        id: playArea; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.activePlayer?.togglePlaying()
                    }
                }

                // Proxima
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: nextArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    scale: nextArea.pressed ? 0.85 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }
                    Text {
                        anchors.centerIn: parent; text: "⏭"
                        color: nextArea.containsMouse ? "white" : Qt.rgba(1,1,1,0.65)
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: nextArea; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.activePlayer?.next()
                    }
                }
            }
        }
    }
}
