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
    focusable: true

    WaylandRegion { id: region }
    Item {
        id: wb; visible: false
        Component.onCompleted: Qt.callLater(function() {
            var w = wb.Window.window
            if (w) region.apply(w, 0, 0, 900, 320)
        })
    }

    function blockBlur() { var w = wb.Window.window; if (w) region.apply(w, 0, 0, 900, 320) }
    function allowBlur()  { var w = wb.Window.window; if (w) region.clear(w) }

    // Estado
    property string currentTab: AppState.overlayCurrentTab
    onCurrentTabChanged: {
        if (currentTab === "") keyItem.forceActiveFocus()
    }

    Connections {
        target: AppState
        function onOverlayOpenChanged() {
            if (AppState.overlayOpen) {
                closeAnim.stop()
                morph.width  = 260; morph.height = 32
                morph.showContent = false
                morph.visible = true
                AppState.overlayCurrentTab = ""
                keyItem.forceActiveFocus()
                openAnim.start()
            } else {
                openAnim.stop()
                morph.showContent = false
                AppState.overlayCurrentTab = ""
                win.blockBlur()
                closeAnim.start()
            }
        }
    }

    property int catHovered: 0
    property var cats: ["Wallpaper", "Configs", "Apps", "Performance", "Sobre"]

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 160; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "height"; to: 320; duration: 500; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 960; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "width";  to: 860; duration: 140; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 900; duration: 120; easing.type: Easing.InOutCubic }
        ScriptAction { script: { win.allowBlur(); morph.showContent = true } }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: morph; property: "width";  to: 940; duration: 90;  easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 240; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "height"; to: 32;  duration: 420; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 280; duration: 200; easing.type: Easing.OutBack }
        ScriptAction { script: { morph.visible = false; AppState.overlayFullyClosed() } }
    }

    Item {
        id: morph
        focus: false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 260; height: 32
        visible: false
        clip: true
        layer.enabled: true
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 60 ? parent.height / 2 : 20
            color: Qt.rgba(0.06, 0.06, 0.10, 0.30)
            antialiasing: true
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
            }
        }

        // Item que recebe teclado
        Item {
            id: keyItem
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: {
                if (win.currentTab !== "") { AppState.overlayCurrentTab = "" }
                else { AppState.toggle() }
            }
            Keys.onUpPressed: {
                if (win.currentTab === "") win.catHovered = Math.max(0, win.catHovered - 1)
                else if (win.currentTab === "Wallpaper") AppState.activeWallRow = Math.max(0, AppState.activeWallRow - 1)
            }
            Keys.onDownPressed: {
                if (win.currentTab === "") win.catHovered = Math.min(win.cats.length - 1, win.catHovered + 1)
                else if (win.currentTab === "Wallpaper") AppState.activeWallRow = Math.min(1, AppState.activeWallRow + 1)
            }
            Keys.onReturnPressed: {
                if (win.currentTab === "") AppState.overlayCurrentTab = win.cats[win.catHovered]
            }
        }

        // Conteudo
        Item {
            anchors.fill: parent
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // ── TELA INICIAL ──
            Item {
                id: idleScreen
                anchors.fill: parent
                opacity: win.currentTab === "" ? 1 : 0
                scale:   win.currentTab === "" ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                // Categorias esquerda
                Column {
                    id: catList
                    anchors.left: parent.left; anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    property int hovered: win.catHovered
                    property var cats: win.cats

                    Repeater {
                        model: catList.cats
                        Text {
                            text: modelData
                            color: catList.hovered === index ? "white" : Qt.rgba(1,1,1,0.45)
                            font.pixelSize: catList.hovered === index ? 16 : 14
                            font.weight: catList.hovered === index ? Font.Medium : Font.Normal
                            Behavior on color     { ColorAnimation { duration: 150 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: catList.hovered = index
                                onExited:  if (catList.hovered === index) catList.hovered = -1
                                onClicked: AppState.overlayCurrentTab = catList.cats[index]
                            }
                        }
                    }
                }

                // Divisor
                Rectangle {
                    anchors.left: catList.right; anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: parent.height * 0.6
                    color: Qt.rgba(1,1,1,0.10)
                }

                // Centro — título + relógio + GIF
                Column {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 40
                    spacing: 6
                    width: 300

                    Text {
                        text: "OshiroOS"
                        color: Qt.rgba(1,1,1,0.7)
                        font.pixelSize: 13; font.weight: Font.Light
                        font.letterSpacing: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Relógio
                    Text {
                        id: clockText
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "white"; font.pixelSize: 38; font.weight: Font.Thin
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                        Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm")
                    }

                    // GIF
                    AnimatedImage {
                        id: gifImg
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120; height: 80
                        fillMode: Image.PreserveAspectFit
                        playing: morph.showContent
                        asynchronous: true
                        source: ""
                        Component.onCompleted: {
                            var proc = Qt.createQmlObject('
                                import Quickshell.Io
                                Process {
                                    running: true
                                    command: ["bash", "-c", "ls ~/Pictures/gif/*.gif 2>/dev/null | head -1"]
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var f = data.trim()
                                            if (f.length > 0) gifImg.source = "file://" + f
                                        }
                                    }
                                }
                            ', gifImg)
                        }
                    }
                }

                // Dica teclado
                Text {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    anchors.right: parent.right; anchors.rightMargin: 16
                    text: "↑↓ navegar  •  Enter selecionar  •  ESC fechar"
                    color: Qt.rgba(1,1,1,0.2); font.pixelSize: 9
                }
            }

            // ── CONTEUDO DA CATEGORIA ──
            Item {
                id: tabScreen
                anchors.fill: parent
                opacity: win.currentTab !== "" ? 1 : 0
                scale:   win.currentTab !== "" ? 1 : 1.04
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                // Breadcrumb topo esquerdo
                Row {
                    anchors.top: parent.top; anchors.topMargin: 10
                    anchors.left: parent.left; anchors.leftMargin: 16
                    spacing: 6
                    Text {
                        text: "←"; color: Qt.rgba(1,1,1,0.4); font.pixelSize: 11
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.overlayCurrentTab = "" }
                    }
                    Text { text: win.currentTab; color: "white"; font.pixelSize: 11; font.weight: Font.Medium }
                }

                // Loader do tab
                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    anchors.topMargin: 30
                    anchors.margins: 8
                    active: true
                    visible: morph.showContent
                    source: win.currentTab === "Wallpaper" ? "tabs/WallpaperTab.qml" : ""
                    onLoaded: item.forceActiveFocus()
                }
            }
        }
    }
}
