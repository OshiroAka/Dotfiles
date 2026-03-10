import Quickshell
import Quickshell.Wayland
import QtQuick
import ShiraOS

PanelWindow {
    id: win

    WlrLayershell.namespace:     "shiraos-island"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1

    anchors.top:  true
    margins.top:  8
    margins.left: screen ? Math.round((screen.width - 260) / 2) : 660

    color:          Qt.rgba(0, 0, 0, 0.01)
    implicitWidth:  260
    implicitHeight: 48
    focusable:      false

    Region { id: emptyMask }
    mask: AppState.islandOpen ? emptyMask : null

    // ── Animação de afastamento/retorno ───────────────────────────────────
    property real pillScale:   1.0
    property real pillOpacity: 1.0

    Connections {
        target: AppState
        function onIslandOpenChanged() {
            if (AppState.islandOpen) {
                // Encolhe — sensação de "ir embora" para o centro
                shrinkAnim.start()
            } else {
                // Espera a island fechar (~300ms), depois pinga de volta
                returnTimer.restart()
            }
        }
    }

    // Encolher ao abrir island
    SequentialAnimation {
        id: shrinkAnim
        NumberAnimation {
            target: win; property: "pillScale"
            to: 0.55
            duration: 280
            easing.type: Easing.InBack
            easing.overshoot: 1.8
        }
        NumberAnimation {
            target: win; property: "pillOpacity"
            to: 0.0
            duration: 80
            easing.type: Easing.InCubic
        }
    }

    // Delay antes de reaparecer (espera island fechar)
    Timer {
        id: returnTimer
        interval: 280
        repeat:   false
        onTriggered: returnAnim.start()
    }

    // Reaparecer com ping elástico
    SequentialAnimation {
        id: returnAnim
        // Reseta estado inicial pequeno
        ScriptAction {
            script: {
                win.pillScale   = 0.4
                win.pillOpacity = 0.0
            }
        }
        // Fade in rápido
        NumberAnimation {
            target: win; property: "pillOpacity"
            to: 1.0
            duration: 80
            easing.type: Easing.OutCubic
        }
        // Ping elástico forte
        NumberAnimation {
            target: win; property: "pillScale"
            to: 1.0
            duration: 420
            easing.type: Easing.OutBack
            easing.overshoot: 2.2
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width:   260
        height:  36
        radius:  height / 2
        color:   Qt.rgba(0.07, 0.07, 0.10, 0.4)
        border.color: Qt.rgba(1,1,1,0.30); border.width: 1

        opacity:         win.pillOpacity
        scale:           win.pillScale
        transformOrigin: Item.Center

        // Sombra
        Rectangle {
            anchors.fill: parent; anchors.margins: -3
            radius: height / 2
            color: "transparent"
            border.color: Qt.rgba(0,0,0,0.30); border.width: 3
            z: -1
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                id: clockText
                anchors.verticalCenter: parent.verticalCenter
                color: "white"; font.pixelSize: 14; font.weight: Font.Medium
                Timer {
                    interval: 1000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:  "ShiraOS"
                color: Qt.rgba(1,1,1,0.45)
                font.pixelSize: 11; font.weight: Font.Light; font.letterSpacing: 2
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 8
                    Rectangle {
                        width: 2; radius: 1
                        color: Qt.rgba(1,1,1,0.55)
                        height: 4 + Math.random() * 12
                        Timer {
                            interval: 120 + index * 30; running: true; repeat: true
                            onTriggered: parent.height = 4 + Math.random() * 12
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: AppState.toggleIsland()
        }
    }
}
