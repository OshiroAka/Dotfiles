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

    // ── Dígitos ──────────────────────────────────────────────────────────
    property int tH1: 0; property int tH2: 0
    property int tM1: 0; property int tM2: 0
    property int tS1: 0; property int tS2: 0

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours(); var m = now.getMinutes(); var s = now.getSeconds()
            win.tH1 = Math.floor(h/10); win.tH2 = h%10
            win.tM1 = Math.floor(m/10); win.tM2 = m%10
            win.tS1 = Math.floor(s/10); win.tS2 = s%10
        }
    }

    // ── Animações pill ───────────────────────────────────────────────────
    property real pillScale: 1.0; property real pillOpacity: 1.0

    Connections {
        target: AppState
        function onIslandOpenChanged() {
            if (AppState.islandOpen) shrinkAnim.start()
            else returnTimer.restart()
        }
    }
    SequentialAnimation {
        id: shrinkAnim
        NumberAnimation { target: win; property: "pillScale";   to: 0.55; duration: 280; easing.type: Easing.InBack; easing.overshoot: 1.8 }
        NumberAnimation { target: win; property: "pillOpacity"; to: 0.0;  duration: 80 }
    }
    Timer { id: returnTimer; interval: 280; repeat: false; onTriggered: returnAnim.start() }
    SequentialAnimation {
        id: returnAnim
        ScriptAction { script: { win.pillScale = 0.4; win.pillOpacity = 0.0 } }
        NumberAnimation { target: win; property: "pillOpacity"; to: 1.0;  duration: 80 }
        NumberAnimation { target: win; property: "pillScale";   to: 1.0;  duration: 420; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
    }

    // ── Slot digit ───
    component SlotDigit: Item {
        id: sd
        property int  value:  0
        property int  maxVal: 9
        property real bigPx:  18
        property real smPx:   7

        width: bigPx * 0.65; height: 44; clip: true
        property real slideY: 0

        onValueChanged: { slideY = 14; slideAnim.restart() }

        NumberAnimation {
            id: slideAnim; target: sd; property: "slideY"
            to: 0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.5
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height/2 - bigPx*0.65 - sd.smPx - 2 - sd.slideY
            spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (sd.value - 1 + sd.maxVal + 1) % (sd.maxVal + 1)
                color: Qt.rgba(1,1,1,0.15); font.pixelSize: sd.smPx
                font.family: "monospace"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: sd.value; color: "white"
                font.pixelSize: sd.bigPx; font.weight: Font.Medium
                font.family: "monospace"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (sd.value + 1) % (sd.maxVal + 1)
                color: Qt.rgba(1,1,1,0.15); font.pixelSize: sd.smPx
                font.family: "monospace"
            }
        }
    }

    // ── Pill ──────────────---
    Rectangle {
        anchors.centerIn: parent
        width: 260; height: 36; radius: 18
        color: Qt.rgba(0.07, 0.07, 0.10, 0.4)
        border.color: Qt.rgba(1,1,1,0.28); border.width: 1
        opacity: win.pillOpacity; scale: win.pillScale
        transformOrigin: Item.Center; clip: true

        // ShiraOS — esquerda, absoluto
        Text {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "ShiraOS"; color: Qt.rgba(1,1,1,0.35)
            font.pixelSize: 10; font.letterSpacing: 1.5; font.weight: Font.Light
        }
        // Visualizer — direita, absoluto
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: 7
                Rectangle {
                    id: vbar; width: 2; radius: 1; color: Qt.rgba(1,1,1,0.45)
                    height: 3 + Math.random() * 9
                    Timer {
                        interval: 100 + index * 40; running: true; repeat: true
                        onTriggered: vbar.height = 3 + Math.random() * 9
                    }
                    Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.InOutSine } }
                }
            }
        }
                Row {
            anchors.centerIn: parent
            spacing: 1

            SlotDigit { value: win.tH1; maxVal: 2; bigPx: 18; smPx: 7 }
            SlotDigit { value: win.tH2; maxVal: 9; bigPx: 18; smPx: 7 }

            // Separador :
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Rectangle { width: 2; height: 2; radius: 1; color: Qt.rgba(1,1,1,0.5) }
                Rectangle { width: 2; height: 2; radius: 1; color: Qt.rgba(1,1,1,0.5) }
            }

            Item { width: 2; height: 1 }
            SlotDigit { value: win.tM1; maxVal: 5; bigPx: 18; smPx: 7 }
            SlotDigit { value: win.tM2; maxVal: 9; bigPx: 18; smPx: 7 }

            // Separador :
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Rectangle { width: 2; height: 2; radius: 1; color: Qt.rgba(1,1,1,0.5) }
                Rectangle { width: 2; height: 2; radius: 1; color: Qt.rgba(1,1,1,0.5) }
            }

            Item { width: 2; height: 1 }
            // Segundos menores
            SlotDigit { value: win.tS1; maxVal: 5; bigPx: 18; smPx: 7 }
            SlotDigit { value: win.tS2; maxVal: 9; bigPx: 18; smPx: 7 }
        }

        MouseArea { anchors.fill: parent; onClicked: AppState.toggleIsland() }
    }
}

