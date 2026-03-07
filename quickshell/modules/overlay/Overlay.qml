import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../shared"
import OshiroShell 1.0

PanelWindow {
    id: win
    anchors.top: true; anchors.left: true
    margins.top: 8
    margins.left: screen ? Math.round((screen.width - 900) / 2) : 510
    color: "transparent"
    implicitWidth: 900; implicitHeight: 320
    visible: true; focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppState.overlayOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region { id: emptyMask }
    mask: (AppState.overlayOpen && !AppState.wallpaperOpen) ? null : emptyMask

    WaylandRegion { id: region }
    Item { id: wb; visible: false }
    Timer { id: startupTimer; interval: 1500; repeat: false
        onTriggered: { var w=wb.Window.window; if(w) region.apply(w,0,0,900,320) }
    }
    Component.onCompleted: startupTimer.start()

    // Cores adaptativas
    property color gc1: Qt.rgba(0.06,0.06,0.12,1)
    property color gc2: Qt.rgba(0.10,0.08,0.18,1)
    property color gc3: Qt.rgba(0.08,0.06,0.14,1)
    property color gc4: Qt.rgba(0.12,0.10,0.20,1)
    property color tc:  "white"
    property color tcd: Qt.rgba(1,1,1,0.45)
    property bool isDark: true

    property var cats: ["Wallpaper", "Menu", "Configs", "Apps", "Performance", "Sobre"]
    property int catHov: 0
    property string currentTab: AppState.overlayCurrentTab
    property bool pendingWallpaper: false
    property bool pendingMenu: false

    Process {
        id: colorProc; running: false; property int lc: 0
        command: ["bash","-c",
            "wall=$(swww query 2>/dev/null | grep -o 'image: .*' | sed 's/image: //' | head -1); " +
            "[ -z \"$wall\" ] && echo '0.06 0.06 0.12' && echo '0.10 0.08 0.18' && echo '0.08 0.06 0.14' && echo '0.12 0.10 0.20' && exit; " +
            "convert \"$wall\" -resize 50x50! +dither -colors 4 -format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null | head -4"]
        stdout: SplitParser { onRead: data => {
            var p=data.trim().split(" ")
            if(p.length>=3){
                var r=Math.min(parseFloat(p[0])*1.1,0.60), g=Math.min(parseFloat(p[1])*1.1,0.60), b=Math.min(parseFloat(p[2])*1.1,0.60)
                if(colorProc.lc===0) win.gc1=Qt.rgba(r,g,b,1)
                else if(colorProc.lc===1) win.gc2=Qt.rgba(r,g,b,1)
                else if(colorProc.lc===2) win.gc3=Qt.rgba(r,g,b,1)
                else if(colorProc.lc===3) {
                    win.gc4=Qt.rgba(r,g,b,1)
                    var avg=(win.gc1.r+win.gc1.g+win.gc1.b+win.gc2.r+win.gc2.g+win.gc2.b)/6
                    win.isDark=avg<0.5
                    win.tc=win.isDark?"white":"black"
                    win.tcd=win.isDark?Qt.rgba(1,1,1,0.45):Qt.rgba(0,0,0,0.45)
                }
                colorProc.lc++
            }
        }}
        onRunningChanged: if(running) lc=0
    }
    Timer { interval: 3000; running: AppState.overlayOpen; repeat: true
        onTriggered: { colorProc.running=false; colorProc.running=true } }



    Process {
        id: saveGifProc; running: false
        command: ["bash","-c",
            "mkdir -p /home/oshiro/.config/quickshell/state && " +
            "printf '%s' '" + AppState.selectedGif + "' > /home/oshiro/.config/quickshell/state/selected_gif.txt"]
    }
    Process {
        id: loadGifProc; running: true
        command: ["bash","-c","cat /home/oshiro/.config/quickshell/state/selected_gif.txt 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => {
            var f = data.trim()
            if (f.length > 0 && AppState.selectedGif === "") AppState.selectedGif = f
        }}
    }

    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                openAnim.stop(); closeAnim.stop()
                morph.showContent=false; morph.visible=false
                var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
            }
        }
        function onOverlayOpenChanged() {
            if (!AppState.overlayOpen && win.pendingWallpaper) {
                win.pendingWallpaper=false; AppState.wallpaperOpen=true; return
            }
            if (!AppState.overlayOpen && win.pendingMenu) {
                win.pendingMenu=false; AppState.menuOpen=true; return
            }
            if (AppState.overlayOpen) {
                closeAnim.stop(); morph.opacity=1
                var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
                morph.width=260; morph.height=32; morph.showContent=false; morph.visible=true
                colorProc.running=false; colorProc.running=true
                openAnim.start()
            } else {
                openAnim.stop(); morph.showContent=false
                closeAnim.start()
            }
        }
        function onSelectedGifChanged() {
            gifImg.source = "file://" + AppState.selectedGif
            saveGif.running=false; saveGif.running=true
        }
    }

    // Animação wallpaperExit
    SequentialAnimation {
        id: wallpaperExitAnim
        NumberAnimation { target: morph; property: "opacity"; to: 0; duration: 320; easing.type: Easing.InOutCubic }
        ScriptAction { script: { morph.visible=false; morph.opacity=1; AppState.overlayOpen=false } }
    }

    SequentialAnimation {
        id: openAnim
        ScriptAction { script: { morph.opacity=1; morph.width=260; morph.height=32; morph.scale=1 } }
        // Fase 1: expande largura rapidamente como um "shoot"
        ParallelAnimation {
            NumberAnimation { target: morph; property: "width";  to: 960; duration: 220; easing.type: Easing.OutExpo }
            NumberAnimation { target: morph; property: "height"; to: 48;  duration: 180; easing.type: Easing.OutCubic }
        }
        // Fase 2: abre altura com personalidade + volta largura
        ParallelAnimation {
            NumberAnimation { target: morph; property: "height"; to: 340; duration: 460; easing.type: Easing.OutBack }
            NumberAnimation { target: morph; property: "width";  to: 880; duration: 320; easing.type: Easing.OutCubic }
        }
        // Fase 3: ajuste final suave
        NumberAnimation { target: morph; property: "width"; to: 900; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "height"; to: 320; duration: 120; easing.type: Easing.OutCubic }
        ScriptAction { script: { var w=wb.Window.window; if(w) region.clear(w); morph.showContent=true } }
        PauseAnimation { duration: 40 }
        ScriptAction { script: keyItem.forceActiveFocus() }
    }

    SequentialAnimation {
        id: closeAnim
        ScriptAction { script: morph.showContent=false }
        PauseAnimation { duration: 20 }
        // Fase 1: encolhe altura rápido (inverso do shoot)
        ParallelAnimation {
            NumberAnimation { target: morph; property: "height"; to: 48;  duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { target: morph; property: "width";  to: 960; duration: 100; easing.type: Easing.InCubic }
        }
        // Fase 2: contrai para pill
        ParallelAnimation {
            NumberAnimation { target: morph; property: "height"; to: 32;  duration: 180; easing.type: Easing.InExpo }
            NumberAnimation { target: morph; property: "width";  to: 260; duration: 220; easing.type: Easing.InExpo }
        }
        // Fade final
        NumberAnimation { target: morph; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
        ScriptAction { script: {
            morph.visible=false; morph.opacity=1; morph.width=260; morph.height=32
            var w=wb.Window.window; if(w) region.apply(w,0,0,900,320)
            AppState.overlayFullyClosed()
        }}
    }

    Item {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 260; height: 32
        visible: false; clip: true; layer.enabled: false
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 70 ? parent.height/2 : 22
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
            Keys.onLeftPressed:  if(win.currentTab==="" ) win.catHov=Math.max(0,win.catHov-1)
            Keys.onRightPressed: if(win.currentTab==="" ) win.catHov=Math.min(win.cats.length-1,win.catHov+1)
            Keys.onReturnPressed: {
                if (win.currentTab==="") {
                    var cat=win.cats[win.catHov]
                    if (cat==="Wallpaper") {
                        win.pendingWallpaper=true
                        openAnim.stop(); closeAnim.stop()
                        morph.showContent=false
                        wallpaperExitAnim.start()
                    } else if (cat==="Menu") {
                        win.pendingMenu=true
                        openAnim.stop(); closeAnim.stop()
                        morph.showContent=false
                        wallpaperExitAnim.start()
                    } else AppState.overlayCurrentTab=cat
                }
            }
        }

        Item {
            anchors.fill: parent
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // TELA INICIAL
            Item {
                id: homeScreen
                anchors.fill: parent
                opacity: win.currentTab==="" ? 1 : 0
                scale:   win.currentTab==="" ? 1 : 0.97
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                visible: opacity > 0
                clip: true

                // ── Cava barras ──
                property var vizBars: Array(40).fill(0.05)
                Process {
                    id: cavaProc; running: false
                    command: ["bash","-c",
                        "mkdir -p /tmp/qs_cava; cat > /tmp/qs_cava/cava.conf << 'EOF'\n[general]\nbars=40\nframerate=30\n[input]\nmethod=pipewire\n[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100\nEOF\ncava -p /tmp/qs_cava/cava.conf 2>/dev/null"]
                    stdout: SplitParser { onRead: data => {
                        var p = data.trim().split(";")
                        if (p.length >= 40) {
                            var a = []
                            for (var k=0; k<40; k++) a.push(Math.max(0.03, Math.min(1.0, parseInt(p[k]||"0")/100)))
                            homeScreen.vizBars = a
                        }
                    }}
                }
                Timer {
                    interval: 500; running: morph.showContent && win.currentTab===""
                    repeat: false
                    onTriggered: { cavaProc.running=false; cavaProc.running=true }
                }

                // ── Visualizador topo ──
                Row {
                    id: vizRow
                    anchors.top: parent.top; anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 40
                    height: 24
                    spacing: 2

                    Repeater {
                        model: 40
                        Rectangle {
                            required property int index
                            width: (vizRow.width - 39*2) / 40
                            height: Math.max(3, vizRow.height * homeScreen.vizBars[index])
                            anchors.bottom: parent ? parent.bottom : undefined
                            radius: 2
                            color: Qt.rgba(
                                win.gc2.r * 0.2 + 0.7,
                                win.gc2.g * 0.2 + 0.6,
                                win.gc2.b * 0.2 + 0.9,
                                0.4 + homeScreen.vizBars[index] * 0.5)
                            Behavior on height { NumberAnimation { duration: 80 } }
                        }
                    }
                }

                // ── Separador ──
                Rectangle {
                    anchors.top: vizRow.bottom; anchors.topMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 60; height: 1
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.3; color: Qt.rgba(win.tc.r,win.tc.g,win.tc.b,0.18) }
                        GradientStop { position: 0.7; color: Qt.rgba(win.tc.r,win.tc.g,win.tc.b,0.18) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // ── Relógio — centro absoluto ──
                Item {
                    id: clkBlock
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: vizRow.bottom; anchors.topMargin: 16
                    width: clkMain.width; height: clkMain.height + catLabel.height + 6

                    property string t: Qt.formatTime(new Date(),"hh:mm:ss")
                    Timer { interval:1000; running:true; repeat:true; onTriggered: parent.t=Qt.formatTime(new Date(),"hh:mm:ss") }

                    Text {
                        text: clkBlock.t
                        font.pixelSize: 88; font.weight: Font.Black
                        color: "transparent"; style: Text.Outline
                        styleColor: Qt.rgba(win.tc.r,win.tc.g,win.tc.b,0.08)
                        anchors.centerIn: clkMain
                        anchors.horizontalCenterOffset: 1; anchors.verticalCenterOffset: 1
                    }
                    Text {
                        id: clkMain
                        text: clkBlock.t
                        font.pixelSize: 88; font.weight: Font.Black
                        color: win.tc; opacity: 0.92
                    }
                    Text {
                        id: catLabel
                        anchors.horizontalCenter: clkMain.horizontalCenter
                        anchors.top: clkMain.bottom; anchors.topMargin: 6
                        text: win.cats[win.catHov]
                        color: win.tc; font.pixelSize: 16; font.weight: Font.Bold; opacity: 0.85
                        Behavior on text { }
                        scale: 1.0
                        SequentialAnimation on scale {
                            running: false; id: catAnim
                            NumberAnimation { to: 0.75; duration: 80; easing.type: Easing.InCubic }
                            NumberAnimation { to: 1.0;  duration: 200; easing.type: Easing.OutBack }
                        }
                        onTextChanged: catAnim.running = true
                    }
                }


                // ── Data + ShiraOS ──
                Column {
                    anchors.right: parent.right; anchors.rightMargin: 20
                    anchors.verticalCenter: clkBlock.verticalCenter

                    Text {
                        anchors.right: parent.right
                        property string d: Qt.formatDate(new Date(),"dddd, d MMMM")
                        Timer { interval:60000; running:true; repeat:true; onTriggered: parent.d=Qt.formatDate(new Date(),"dddd, d MMMM") }
                        text: d; color: win.tcd; font.pixelSize: 11
                    }
                    Text {
                        anchors.right: parent.right
                        text: "ShiraOS"; font.pixelSize: 9; font.weight: Font.Medium
                        font.letterSpacing: 2.5; color: win.tcd; opacity: 0.45
                    }
                }

                // ── Carrossel de categorias ──
                Item {
                    id: catRow
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    anchors.left: parent.left; anchors.right: parent.right
                    height: 26
                    property real slotW: width / 3

                    Repeater {
                        model: win.cats
                        Item {
                            required property string modelData
                            required property int index
                            property int dist: index - win.catHov
                            property bool isActive: dist === 0
                            anchors.verticalCenter: parent.verticalCenter
                            x: catRow.width/2 - tabLbl.width/2 + dist * catRow.slotW
                            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            opacity: isActive ? 0.0 : Math.abs(dist)===1 ? 0.55 : Math.abs(dist)===2 ? 0.18 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            scale: isActive ? 1.1 : Math.abs(dist)===1 ? 0.88 : 0.75
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Text {
                                id: tabLbl; text: modelData
                                color: isActive ? win.tc : win.tcd
                                font.pixelSize: isActive ? 13 : 11
                                font.weight: isActive ? Font.Bold : Font.Normal
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                            Rectangle {
                                anchors.horizontalCenter: tabLbl.horizontalCenter
                                anchors.top: tabLbl.bottom; anchors.topMargin: 3
                                width: isActive ? tabLbl.width * 0.6 : 0; height: 2; radius: 1
                                color: win.tc; opacity: 0.75
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }
                            MouseArea {
                                anchors.fill: tabLbl; anchors.margins: -10
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: win.catHov = index
                                onClicked: {
                                    win.catHov = index
                                    var cat = win.cats[index]
                                    if (cat==="Wallpaper") { win.pendingWallpaper=true; openAnim.stop(); closeAnim.stop(); morph.showContent=false; wallpaperExitAnim.start()
                                    } else if (cat==="Menu") { win.pendingMenu=true; openAnim.stop(); closeAnim.stop(); morph.showContent=false; wallpaperExitAnim.start()
                                    } else AppState.overlayCurrentTab = cat
                                }
                            }
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position:0.0; color: Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,0.98) }
                            GradientStop { position:1.0; color: Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,0.0) }
                        }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position:0.0; color: Qt.rgba(win.gc4.r,win.gc4.g,win.gc4.b,0.0) }
                            GradientStop { position:1.0; color: Qt.rgba(win.gc4.r,win.gc4.g,win.gc4.b,0.98) }
                        }
                    }
                }
            }





            // TAB CONTENT
            Loader {
                anchors.fill: parent
                active: win.currentTab !== ""
                opacity: win.currentTab!=="" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                source: win.currentTab==="Menu" ? "tabs/MenuTab.qml" : ""
            }
        }
    }
}
