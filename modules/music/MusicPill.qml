import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win

    anchors.top: true
    margins.top: 8
    color: Qt.rgba(0, 0, 0, 0.01)

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

    readonly property real duration: {
        if (!activePlayer || activePlayer.trackLength <= 0) return 1
        return activePlayer.trackLength * 1000
    }

    property bool hovered: false
    property bool expanded: hovered && activePlayer !== null

    // ------------------------------------------------------------
    // Componente principal: pill arredondado
    // ------------------------------------------------------------
    Rectangle {
        id: pill
        clip: true
        antialiasing: true

        width: win.expanded ? win.expandedW : win.collapsedW
        height: win.expanded ? win.expandedH : win.collapsedH
        radius: win.expanded ? 34 : height / 2
        color: "transparent"

        Behavior on width {
            NumberAnimation {
                duration: 50
                easing.type: Easing.OutQuart
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 50
                easing.type: Easing.OutQuart
            }
        }

        HoverHandler {
            onHoveredChanged: win.hovered = hovered
        }

        // Fundo sólido com transparência
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            antialiasing: true
            color: Qt.rgba(0.08, 0.08, 0.12, 0.3)
        }

        // Borda suave (opcional)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.02)
            border.width: 1
        }

        // --------------------------------------------------------
        // Conteúdo principal: usaremos um único Item que se adapta
        // --------------------------------------------------------
        Item {
            anchors.fill: parent
            anchors.margins: 10  // margem interna para não colar na borda

            // Capa do álbum (única) que se move e redimensiona
            Rectangle {
                id: cover
                width: win.expanded ? 44 : 22
                height: win.expanded ? 44 : 22
                radius: win.expanded ? 8 : 11
                color: "#333"
                clip: true
                antialiasing: true

                // Posicionamento: no modo colapsado fica à esquerda, no expandido também
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 0

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuart
                    }
                }

                Image {
                    anchors.fill: parent
                    source: win.albumArt
                    fillMode: Image.PreserveAspectCrop
                    visible: win.albumArt !== ""
                }
                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: win.albumArt === "" ? "white" : "#888"
                    font.pixelSize: win.expanded ? 20 : 12
                    visible: win.albumArt === ""
                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                    }
                }
            }

            // Título e artista (sempre visíveis, mas com layout diferente)
            Column {
                id: textColumn
                anchors.left: cover.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - cover.width - 8 - (win.expanded ? 70 : 30) // espaço para os controles

                Text {
                    width: parent.width
                    text: win.songTitle
                    color: "white"
                    font.pixelSize: win.expanded ? 14 : 13
                    font.weight: win.expanded ? Font.SemiBold : Font.Medium
                    elide: Text.ElideRight
                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                    }
                }
                Text {
                    width: parent.width
                    text: win.songArtist
                    color: Qt.rgba(1,1,1,0.55)
                    font.pixelSize: win.expanded ? 12 : 10
                    elide: Text.ElideRight
                    visible: win.expanded  // só mostra artista no expandido
                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                    }
                }
            }

            // Barrinhas animadas (só no colapsado)
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                visible: !win.expanded && win.isPlaying
                opacity: win.expanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: 3
                    Rectangle {
                        width: 3; height: 8; radius: 1.5
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true
                        SequentialAnimation on height {
                            loops: Animation.Infinite
                            running: win.isPlaying && !win.expanded
                            NumberAnimation { to: 14; duration: 300 + index * 80; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 5;  duration: 300 + index * 80; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // Controles (só no expandido)
            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: win.expanded
                opacity: win.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                ControlBtn { icon: "\u23ee"; onClicked: win.activePlayer?.previous() }
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: Qt.rgba(1,1,1,0.12)
                    Text {
                        anchors.centerIn: parent
                        text: win.isPlaying ? "\u23f8" : "\u25b6"
                        color: "white"; font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.activePlayer?.togglePlaying()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                ControlBtn { icon: "\u23ed"; onClicked: win.activePlayer?.next() }
            }
        }
    }

    // ------------------------------------------------------------
    // Função para formatar tempo (µs → mm:ss)
    // ------------------------------------------------------------
    function formatTime(us) {
        var totalSeconds = Math.floor(us / 1000000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + String(seconds).padStart(2, "0")
    }

    // Timer para atualizar a posição (caso o player não envie updates)
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