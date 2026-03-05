import Quickshell
import Quickshell.Wayland
import QtQuick
import "../shared"
import OshiroShell 1.0

PanelWindow {
    id: win
    anchors.top: true
    anchors.left: true
    margins.top: 8
    margins.left: screen ? Math.round((screen.width - 900) / 2) : 510
    color: "transparent"
    implicitWidth:  900
    implicitHeight: 320
    visible: true

    WaylandRegion { id: region }
    Item { id: wb; visible: false }

    function blockBlur() {
        var w = wb.Window.window
        if (w) region.apply(w, 0, 0, 900, 420)
    }
    function allowBlur() {
        var w = wb.Window.window
        if (w) region.clear(w)
    }

    Connections {
        target: AppState
        function onOverlayOpenChanged() {
            if (AppState.overlayOpen) {
                closeAnim.stop()
                // Começa como pill
                morph.width  = 260
                morph.height = 32
                morph.showContent = false
                win.blockBlur()
                win.visible = true
                openAnim.start()
            } else {
                openAnim.stop()
                morph.showContent = false
                win.blockBlur()
                closeAnim.start()
            }
        }
    }

    // ABERTURA: pill → fino → alto → largo com overshoot
    SequentialAnimation {
        id: openAnim
        // 1. Encolhe para fino
        NumberAnimation {
            target: morph; property: "width"
            to: 4; duration: 1
            easing.type: Easing.InCubic
        }
        // 2. Sobe (mais lento)
        NumberAnimation {
            target: morph; property: "height"
            to: 320; duration: 1
            easing.type: Easing.InOutCubic
        }
        // 3. Expande com overshoot
        NumberAnimation {
            target: morph; property: "width"
            to: 960; duration: 280
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 860; duration: 200
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 900; duration: 140
            easing.type: Easing.InOutCubic
        }
        // Delay de 2 frames para Wayland processar antes do blur
        ScriptAction {
            script: {
                blurTimer.start()
                morph.showContent = true
            }
        }
    }

    // FECHAMENTO: largo → fino → baixo → pill → some
    SequentialAnimation {
        id: closeAnim
        // Blur some imediatamente
        ScriptAction { script: win.blockBlur() }
        // 1. Overshoot + encolhe largura
        NumberAnimation {
            target: morph; property: "width"
            to: 940; duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: morph; property: "width"
            to: 4; duration: 120
            easing.type: Easing.InCubic
        }
        // 2. Desce (mais lento)
        NumberAnimation {
            target: morph; property: "height"
            to: 32; duration: 420
            easing.type: Easing.InOutCubic
        }
        // 3. Expande de volta ao tamanho do pill
        NumberAnimation {
            target: morph; property: "width"
            to: 280; duration: 200
            easing.type: Easing.OutBack
        }
        // 4. Some — pill real aparece
        ScriptAction {
            script: {
                win.visible = false
                AppState.overlayFullyClosed()
            }
        }
    }

    Timer {
        id: blurTimer
        interval: 1; repeat: false
        onTriggered: win.allowBlur()
    }

    Item {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 260; height: 32
        clip: true
        layer.enabled: true
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 60 ? parent.height / 2 : 20
            color: Qt.rgba(0.06, 0.06, 0.10, 0.400)
            antialiasing: true
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.10)
                border.width: 1; antialiasing: true
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 12
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Loader {
                anchors.fill: parent
                source: "tabs/WallpaperTab.qml"
                active: morph.showContent
            }
        }
    }
}
