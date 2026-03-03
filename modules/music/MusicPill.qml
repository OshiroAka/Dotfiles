import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win

    // Posição e transparência da janela
    anchors.top: true
    margins.top: 8
    color: Qt.rgba(0, 0, 0, 0.01)

    // Tamanhos predefinidos
    readonly property int collapsedW: 220
    readonly property int collapsedH: 36
    readonly property int expandedW: 400
    readonly property int expandedH: 118

    width: pill.width + 2
    height: pill.height + 2

    // Player ativo (Spotify, etc.)
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

    // Posição simulada (para players que não atualizam sozinhos)
    property real livePosition: 0

    // Duração total (convertida para microssegundos)
    readonly property real duration: {
        if (!activePlayer || activePlayer.trackLength <= 0) return 1
        return activePlayer.trackLength * 1000
    }

    // Controle de hover/expansão
    property bool hovered: false
    property bool expanded: hovered && activePlayer !== null

    // ------------------------------------------------------------
    // Componente principal: pill arredondado
    // ------------------------------------------------------------
    Rectangle {
        id: pill
        clip: true   // Garante que nada vaze dos cantos

        width: win.expanded ? win.expandedW : win.collapsedW
        height: win.expanded ? win.expandedH : win.collapsedH
        radius: win.expanded ? 34 : height / 2
        color: "transparent"

        Behavior on width {
         NumberAnimation {
        duration: 300
        easing.type: Easing.InOutCubic
    }
}
        Behavior on height {
         NumberAnimation {
        duration: 300
        easing.type: Easing.InOutCubic
    }
}

        HoverHandler {
            onHoveredChanged: win.hovered = hovered
        }

        // Fundo sólido com transparência (ajuste o alpha para mais ou menos transparência)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(0.08, 0.08, 0.12, 0.3)   // Quanto menor o último valor, mais transparente
        }

        // Borda extremamente suave (opcional – comente se não quiser)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.02)   // Quase invisível
            border.width: 1
        }

        // ========== MODO COLAPSADO ==========
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 8
            opacity: win.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Ícone/Album art pequeno
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

            // Título da música
            Text {
                Layout.fillWidth: true
                text: win.songTitle
                color: "white"; font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            // Barrinhas animadas (quando está tocando)
            Row {
                spacing: 2
                visible: win.isPlaying
                Repeater {
                    model: 3
                    Rectangle {
                        width: 3; height: 8; radius: 1.5
                        color: "#ffffff"
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

        // ========== MODO EXPANDIDO ==========
        Item {
            anchors.fill: parent
            anchors.margins: 14
            opacity: win.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            visible: opacity > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Linha superior: album + título/artista
                RowLayout {
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

                // Controles (play/pause, anterior, próximo)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
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