import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    anchors.top: true
    margins.top: 8
    color: "transparent"

    readonly property int collapsedW: 220
    readonly property int collapsedH: 36
    readonly property int expandedW: 420
    readonly property int expandedH: 118
    implicitWidth: pill.width + 2
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

    Process { id: launchSpotify; command: ["spotify"] }
    Process { id: launchDiscord; command: ["discord"] }

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

        state: win.expanded ? "expanded" : "collapsed"

        states: [
            State {
                name: "collapsed"
                PropertyChanges { target: pill; width: win.collapsedW; height: win.collapsedH; radius: win.collapsedH / 2 }
                PropertyChanges { target: collapsedContent; opacity: 1 }
                PropertyChanges { target: expandedContent; opacity: 0 }
            },
            State {
                name: "expanded"
                PropertyChanges { target: pill; width: win.expandedW; height: win.expandedH; radius: 34 }
                PropertyChanges { target: collapsedContent; opacity: 0 }
                PropertyChanges { target: expandedContent; opacity: 1 }
            }
        ]

        transitions: [
            Transition {
                from: "collapsed"; to: "expanded"
                SequentialAnimation {
                    // 1. Some o conteúdo colapsado rapidamente
                    NumberAnimation { target: collapsedContent; property: "opacity"; duration: 80; to: 0; easing.type: Easing.InOutCubic }
                    // 2. Animação de altura
                    NumberAnimation { 
                        target: pill; property: "height"; 
                        duration: 400; 
                        easing.type: Easing.OutBack; 
                        easing.overshoot: 4
                    }
                    // 3. Animação de largura
                    NumberAnimation { 
                        target: pill; property: "width"; 
                        duration: 420; 
                        easing.type: Easing.OutBack; 
                        easing.overshoot: 5
                    }
                    // 4. Aparece o conteúdo expandido suavemente
                    NumberAnimation { target: expandedContent; property: "opacity"; duration: 200; to: 1; easing.type: Easing.InOutCubic }
                }
            },
            Transition {
                from: "expanded"; to: "collapsed"
                SequentialAnimation {
                    // 1. Some o conteúdo expandido rapidamente
                    NumberAnimation { target: expandedContent; property: "opacity"; duration: 80; to: 0; easing.type: Easing.InOutCubic }
                    // 2. Animação de altura e largura juntas (parallel)
                    ParallelAnimation {
                        NumberAnimation { 
                            target: pill; property: "height"; 
                            duration: 400; 
                            easing.type: Easing.OutBack; 
                            easing.overshoot: 2
                        }
                        NumberAnimation { 
                            target: pill; property: "width"; 
                            duration: 420; 
                            easing.type: Easing.OutBack; 
                            easing.overshoot: 0.7
                        }
                    }
                    // 3. Aparece o conteúdo colapsado suavemente
                    NumberAnimation { target: collapsedContent; property: "opacity"; duration: 1000; to: 1; easing.type: Easing.InOutCubic }
                }
            }
        ]

        MouseArea {
            anchors.fill: parent
            onClicked: {
                win.expanded = !win.expanded
                mouse.accepted = true
            }
            cursorShape: Qt.PointingHandCursor
            z: 0
            propagateComposedEvents: false
        }

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: Qt.rgba(0.08, 0.08, 0.12, 0.8)
            antialiasing: true
            z: 1
        }

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "gray"
            border.color: Qt.rgba(0, 0, 0, 0.65)
            border.width: 1
            z: 2
        }

        // ---------- CONTEÚDO COLAPSADO ----------
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
                    anchors.centerIn: parent; text: "♪"; color: "black"
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
                    color: "black"; font.pixelSize: 13; font.weight: Font.Medium
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
                        width: 3; height: 8; radius: 1.5; color: "black"
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

        // ---------- CONTEÚDO EXPANDIDO ----------
        Item {
            id: expandedContent
            anchors.fill: parent
            anchors.margins: 20
            opacity: 0
            z: 4

            Rectangle {
                id: coverExpanded
                width: 44; height: 44; radius: 8
                color: "white"; clip: true; antialiasing: true
                anchors.left: parent.left
                anchors.top: parent.top
                Image {
                    anchors.fill: parent; source: win.albumArt
                    fillMode: Image.PreserveAspectCrop; visible: win.albumArt !== ""
                }
                Text {
                    anchors.centerIn: parent; text: "♪"; color: "black"
                    font.pixelSize: 20; visible: win.albumArt === ""
                }
            }

            Column {
                anchors.left: coverExpanded.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 3
                Text {
                    width: parent.width
                    text: win.songTitle
                    color: "black"; font.pixelSize: 14; font.weight: Font.SemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: win.songArtist
                    color: Qt.rgba(1,1,1,0.90); font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // Linha inferior com os ícones e controles
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -17
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                z: 5

                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 16
                        Rectangle {
                            width: 3; radius: 1.5; height: 8
                            color: win.playerName === "discord" ? "#5865F2" : "#1DB954"
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                running: win.isPlaying && win.expanded
                                NumberAnimation { to: 16; duration: 450 + index * 130; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 4;  duration: 450 + index * 130; easing.type: Easing.InOutQuad }
                            }
                        }
                    }
                }

                AppIcon {
                    iconSource: "../../icons/spotify.svg"
                    bgColor: "#1DB954"
                    pulsing: win.expanded
                    enabled: win.expanded
                    onClicked: {
                        launchSpotify.running = true
                        mouse.accepted = true
                    }
                }
                AppIcon {
                    iconSource: "../../icons/discord.svg"
                    bgColor: "#5865F2"
                    pulsing: win.expanded
                    enabled: win.expanded
                    onClicked: {
                        launchDiscord.running = true
                        mouse.accepted = true
                    }
                }

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: prevArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    scale: prevArea.pressed ? 0.85 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Text {
                        anchors.centerIn: parent; text: "⏮"
                        color: prevArea.containsMouse ? "black" : Qt.rgba(56, 40, 40, 0.65)
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: win.expanded
                        onClicked: {
                            win.activePlayer?.previous()
                            mouse.accepted = true
                        }
                    }
                }

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: playArea.containsMouse ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.15)
                    anchors.verticalCenter: parent.verticalCenter
                    scale: playArea.pressed ? 0.88 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Text {
                        anchors.centerIn: parent
                        text: win.isPlaying ? "⏸" : "▶"
                        color: "black"; font.pixelSize: 16
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: win.expanded
                        onClicked: {
                            win.activePlayer?.togglePlaying()
                            mouse.accepted = true
                        }
                    }
                }

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: nextArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    scale: nextArea.pressed ? 0.85 : 1.0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Text {
                        anchors.centerIn: parent; text: "⏭"
                        color: nextArea.containsMouse ? "black" : Qt.rgba(1,1,1,0.65)
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: win.expanded
                        onClicked: {
                            win.activePlayer?.next()
                            mouse.accepted = true
                        }
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
}