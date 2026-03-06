import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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
    implicitWidth: 900
    implicitHeight: 320
    visible: true
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppState.overlayOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // mask: null = input normal | mask: emptyMask = sem input
    Region { id: emptyMask }
    mask: (AppState.overlayOpen && !AppState.wallpaperOpen) ? null : emptyMask

    WaylandRegion { id: region }
    Item {
        id: wb; visible: false
        Component.onCompleted: startupTimer.start()
    }
    Timer {
        id: startupTimer; interval: 1500; repeat: false
        onTriggered: {
            var w = wb.Window.window
            if (w) region.apply(w, 0, 0, 900, 320)
        }
    }

    // Gradiente adaptativo
    property color gc1: Qt.rgba(0.06, 0.06, 0.12, 1)
    property color gc2: Qt.rgba(0.08, 0.07, 0.15, 1)
    property color gc3: Qt.rgba(0.10, 0.08, 0.18, 1)
    property color gc4: Qt.rgba(0.12, 0.09, 0.20, 1)
    readonly property bool isDark: {
        var r = (gc1.r+gc2.r+gc3.r+gc4.r)/4
        var g = (gc1.g+gc2.g+gc3.g+gc4.g)/4
        var b = (gc1.b+gc2.b+gc3.b+gc4.b)/4
        return (0.299*r+0.587*g+0.114*b) < 0.45
    }
    readonly property color tc:  isDark ? "white" : Qt.rgba(0.05,0.05,0.08,0.95)
    readonly property color tcd: isDark ? Qt.rgba(1,1,1,0.30) : Qt.rgba(0,0,0,0.40)

    Process {
        id: colorProc; running: false
        property int lc: 0
        command: ["bash", "-c",
            "wall=$(swww query 2>/dev/null | grep -o \'image: .*\' | sed \'s/image: //\' | head -1); " +
            "[ -z \"$wall\" ] && echo \'0.06 0.06 0.12\' && echo \'0.10 0.08 0.18\' && exit; " +
            "convert \"$wall\" -resize 50x50! +dither -colors 4 -format \"%[fx:r] %[fx:g] %[fx:b]\n\" info: 2>/dev/null | head -4"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                if (p.length >= 3) {
                    var r=Math.min(parseFloat(p[0])*0.65,0.38), g=Math.min(parseFloat(p[1])*0.65,0.38), b=Math.min(parseFloat(p[2])*0.65,0.38)
                    if (colorProc.lc===0) win.gc1=Qt.rgba(r,g,b,1)
                    else if (colorProc.lc===1) win.gc2=Qt.rgba(r,g,b,1)
                    else if (colorProc.lc===2) win.gc3=Qt.rgba(r,g,b,1)
                    else win.gc4=Qt.rgba(r,g,b,1)
                    colorProc.lc++
                }
            }
        }
        onRunningChanged: if (running) lc=0
    }
    // Atualiza cor em tempo real a cada 3s quando aberto
    Timer { id: colorTimer; interval: 3000; repeat: true; running: AppState.overlayOpen
        onTriggered: colorProc.running = true }
    Timer { interval: 500; running: true; repeat: false; onTriggered: colorProc.running = true }

    property bool pendingWallpaper: false
    property string currentTab: AppState.overlayCurrentTab
    onCurrentTabChanged: if (currentTab === "") keyItem.forceActiveFocus()
    property int catHov: 0
    property var cats: ["Wallpaper", "Configs", "Apps", "Performance", "Sobre"]

    // Esconde pill quando wallpaper aberto
    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                openAnim.stop()
                closeAnim.stop()
                morph.showContent = false
                morph.visible = false
                var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
            }
        }
        function onOverlayOpenChanged() {
            if (!AppState.overlayOpen && win.pendingWallpaper) {
                win.pendingWallpaper=false
                AppState.wallpaperOpen=true
                return
            }
            if (AppState.overlayOpen) {
                closeAnim.stop()
                morph.opacity=1
                var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
                morph.width=260; morph.height=32; morph.showContent=false; morph.visible=true
                AppState.overlayCurrentTab=""
                openAnim.start()
                colorProc.running=true
            } else {
                openAnim.stop(); morph.showContent=false
                AppState.overlayCurrentTab=""
                var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
                closeAnim.start()
            }
        }
    }

    SequentialAnimation {
        id: wallpaperExitAnim
        // altura encolhe sincronizado com WallpaperOverlay abrindo
        NumberAnimation { target: morph; property: "height"; to: 32;  duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "width";  to: 900; duration: 60;  easing.type: Easing.OutCubic }
        ScriptAction { script: {
            morph.visible=false
            AppState.overlayOpen=false
        }}
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 160; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "height"; to: 320; duration: 500; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 960; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "width";  to: 860; duration: 140; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 900; duration: 120; easing.type: Easing.InOutCubic }
        ScriptAction { script: { var w=wb.Window.window; if(w) region.clear(w); morph.showContent = true } }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: morph; property: "width";  to: 940; duration: 90;  easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 240; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "height"; to: 32;  duration: 420; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 280; duration: 200; easing.type: Easing.OutBack }
        ScriptAction { script: {
            morph.visible=false
            var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
            AppState.overlayFullyClosed()
        } }
    }

    Item {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 260; height: 32
        visible: false; clip: true; layer.enabled: true
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 60 ? parent.height/2 : 20
            color: "transparent"; antialiasing: true
            Rectangle {
                anchors.fill: parent; radius: parent.radius; antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,0.30) }
                    GradientStop { position: 0.33; color: Qt.rgba(win.gc2.r,win.gc2.g,win.gc2.b,0.30) }
                    GradientStop { position: 0.66; color: Qt.rgba(win.gc3.r,win.gc3.g,win.gc3.b,0.30) }
                    GradientStop { position: 1.00; color: Qt.rgba(win.gc4.r,win.gc4.g,win.gc4.b,0.30) }
                }
            }
            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: "transparent"
                border.color: Qt.rgba(1,1,1,0.12); border.width: 1
            }
        }

        Item { id: keyItem; anchors.fill: parent; focus: true
            Keys.onEscapePressed: { if(win.currentTab!=="") AppState.overlayCurrentTab=""; else AppState.toggle() }
            Keys.onUpPressed:     if(win.currentTab==="") win.catHov=Math.max(0,win.catHov-1)
            Keys.onDownPressed:   if(win.currentTab==="") win.catHov=Math.min(win.cats.length-1,win.catHov+1)
            Keys.onReturnPressed: {
                if (win.currentTab==="") {
                    var cat=win.cats[win.catHov]
                    if (cat==="Wallpaper") { win.pendingWallpaper=true; AppState.toggle() }
                    else AppState.overlayCurrentTab=cat
                }
            }
        }

        Item {
            anchors.fill: parent
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            // TELA INICIAL
            Item {
                anchors.fill: parent
                opacity: win.currentTab==="" ? 1 : 0; scale: win.currentTab==="" ? 1 : 0.96
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale   { NumberAnimation { duration: 200 } }
                visible: opacity > 0

                // Categorias
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: win.cats
                        Text {
                            required property string modelData; required property int index
                            text: modelData
                            color: win.catHov===index ? win.tc : win.tcd
                            font.pixelSize: win.catHov===index ? 15 : 13
                            font.weight: win.catHov===index ? Font.Medium : Font.Normal
                            leftPadding: win.catHov===index ? 6 : 0
                            Behavior on color          { ColorAnimation { duration: 150 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                            Behavior on leftPadding    { NumberAnimation { duration: 150 } }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: win.catHov=index
                                onClicked: {
                                    var cat=win.cats[index]
                                    if (cat==="Wallpaper") { win.pendingWallpaper=true; AppState.toggle() }
                                    else AppState.overlayCurrentTab=cat
                                } }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left; anchors.leftMargin: 160
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: parent.height*0.55; color: Qt.rgba(1,1,1,0.08)
                }

                // Relógio
                Text {
                    id: clk
                    anchors.right: parent.right; anchors.rightMargin: 32
                    anchors.top: parent.top; anchors.topMargin: 16
                    color: win.tc; font.pixelSize: 88; font.weight: Font.Black
                    Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text=Qt.formatTime(new Date(),"hh:mm") }
                    Component.onCompleted: text=Qt.formatTime(new Date(),"hh:mm")
                }

                Text {
                    id: dt
                    anchors.right: parent.right; anchors.rightMargin: 36
                    anchors.top: clk.bottom; anchors.topMargin: -10
                    color: win.tcd; font.pixelSize: 11
                    Timer { interval: 60000; running: true; repeat: true; onTriggered: dt.text=Qt.formatDate(new Date(),"dddd, d MMM") }
                    Component.onCompleted: text=Qt.formatDate(new Date(),"dddd, d MMM")
                }

                AnimatedImage {
                    id: gifImg
                    anchors.right: parent.right; anchors.rightMargin: 32
                    anchors.top: dt.bottom; anchors.topMargin: 8
                    width: 120; height: 80; fillMode: Image.PreserveAspectFit
                    playing: morph.showContent && win.currentTab===""; asynchronous: true; smooth: true; source: ""
                    Component.onCompleted: {
                        Qt.createQmlObject('
                            import Quickshell.Io
                            Process { running: true
                                command: ["bash","-c","ls ~/Pictures/gif/*.gif 2>/dev/null | head -1"]
                                stdout: SplitParser { onRead: data => { var f=data.trim(); if(f.length>0) gifImg.source="file://"+f } }
                            }
                        ', gifImg)
                    }
                }

                Text {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                    anchors.left: parent.left; anchors.leftMargin: 20
                    text: "ShiraOS"; color: win.tc; font.pixelSize: 22; font.weight: Font.Bold
                }

                Text {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑↓ navegar   Enter selecionar   ESC fechar"
                    color: Qt.rgba(1,1,1,0.18); font.pixelSize: 9
                }
            }

            // CONTEUDO CATEGORIA
            Item {
                anchors.fill: parent
                opacity: win.currentTab!=="" ? 1 : 0; scale: win.currentTab!=="" ? 1 : 1.04
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on scale   { NumberAnimation { duration: 220 } }
                visible: opacity > 0

                Row {
                    anchors.top: parent.top; anchors.topMargin: 10
                    anchors.left: parent.left; anchors.leftMargin: 16
                    spacing: 6
                    Text { text: "←"; color: Qt.rgba(1,1,1,0.4); font.pixelSize: 11
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.overlayCurrentTab="" } }
                    Text { text: win.currentTab; color: "white"; font.pixelSize: 11; font.weight: Font.Medium }
                }

                Loader {
                    anchors.fill: parent; anchors.topMargin: 30; anchors.margins: 8
                    active: true; visible: morph.showContent
                    source: win.currentTab==="Wallpaper" ? "tabs/WallpaperTab.qml" : ""
                    onLoaded: item.forceActiveFocus()
                }
            }
        }
    }
}
