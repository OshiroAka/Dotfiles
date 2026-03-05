import Quickshell
import Quickshell.Wayland
import QtQuick
import "../shared"
import OshiroShell 1.0

PanelWindow {
    id: win
    anchors.top: true
    anchors.left: true
    // Abaixo do pill (pill: top=8, height=32, gap=8)
    margins.top: 48
    margins.left: screen ? Math.round((screen.width - 900) / 2) : 510
    color: "transparent"
    implicitWidth:  900
    implicitHeight: 420
    visible: false

    WaylandRegion { id: region }
    Item { id: wb; visible: false }

    // Atualiza região a cada frame durante animação
    // Região opaca = só o retângulo do morph atual
    // Hyprland aplica blur DENTRO da região opaca
    Timer {
        id: regionTimer
        interval: 16; repeat: true; running: false
        onTriggered: {
            var w = wb.Window.window
            if (!w) return
            var x = Math.round((900 - morph.width) / 2)
            var y = 0
            var mw = Math.max(1, Math.round(morph.width))
            var mh = Math.max(1, Math.round(morph.height))
            region.apply(w, x, y, mw, mh)
        }
    }

    Connections {
        target: AppState
        function onOverlayOpenChanged() {
            if (AppState.overlayOpen) {
                morph.showContent = false
                morph.width  = 4
                morph.height = 32
                win.visible  = true
                regionTimer.running = true
                openAnim.start()
            } else {
                morph.showContent = false
                closeAnim.start()
            }
        }
    }

    // Abertura: alto → largo com overshoot
    SequentialAnimation {
        id: openAnim
        onStopped: {
            regionTimer.running = false
            // Região final = painel inteiro
            var w = wb.Window.window
            if (w) region.apply(w, 0, 0, 900, 420)
            morph.showContent = true
        }

        NumberAnimation {
            target: morph; property: "height"
            to: 420; duration: 340
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 960; duration: 280
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 870; duration: 130
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 900; duration: 110
            easing.type: Easing.InOutCubic
        }
    }

    // Fechamento: estreita com overshoot → fino → baixo
    SequentialAnimation {
        id: closeAnim
        onStarted: regionTimer.running = true
        onStopped: {
            regionTimer.running = false
            win.visible = false
        }

        NumberAnimation {
            target: morph; property: "width"
            to: 940; duration: 100
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 4; duration: 260
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: morph; property: "height"
            to: 32; duration: 260
            easing.type: Easing.InOutCubic
        }
    }

    Rectangle {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        antialiasing: true
        layer.enabled: true
        width: 4; height: 32
        radius: height < 60 ? height / 2 : 20
        color: Qt.rgba(0.06, 0.06, 0.10, 0.88)

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1,1,1,0.10)
            border.width: 1; antialiasing: true
        }

        property bool showContent: false
        Item {
            anchors.fill: parent
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: "overlay — tabs aqui"
                color: Qt.rgba(1,1,1,0.5); font.pixelSize: 15
            }
        }
    }
}
