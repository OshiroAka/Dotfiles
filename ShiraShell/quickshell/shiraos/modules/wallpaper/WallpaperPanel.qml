import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ShiraOS

PanelWindow {
    id: win

    WlrLayershell.namespace:     "shiraos-wallpaper"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: AppState.wallpaperOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true
    color: "transparent"
    focusable: true

    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    // ── Config ───────────────────────────────────────────────
    property real   panelWidthRatio: 0.70
    property int    panelHeight:     220
    property int    thumbW:          280
    property bool   configOpen:      false
    property string swwwTransition:  "grow"
    property string panelPosition:   "center"
    property int    activeCategory:  0       // 0=Engine 1=Static 2=MPV
    readonly property var catNames: ["Engine", "Static", "MPV"]

    // ── State ────────────────────────────────────────────────
    property var staticWalls: []
    property var engineWalls: []
    property var liveWalls:   []

    property int staticIdx: AppState.staticWallIdx
    onStaticIdxChanged: AppState.staticWallIdx = win.staticIdx
    property int engineIdx: 0
    property int liveIdx:   AppState.liveWallIdx

    property var currentWalls: {
        if (activeCategory === 0) return engineWalls
        if (activeCategory === 1) return staticWalls
        return liveWalls
    }
    property int currentIdx: {
        if (activeCategory === 0) return engineIdx
        if (activeCategory === 1) return staticIdx
        return liveIdx
    }

    property color gc1: AppState.accentPill   || Qt.rgba(0.06,0.06,0.12,0.55)
    property color gc2: AppState.accentDark   || Qt.rgba(0.04,0.04,0.10,0.75)
    property color cAc: AppState.accentColor  || Qt.rgba(0.55,0.70,1.00,1.00)
    property color cRm: AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25)

    // ── Animação ─────────────────────────────────────────────
    property real animProgress: 0

    NumberAnimation { id: openAnim;  target: win; property: "animProgress"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
    NumberAnimation { id: closeAnim; target: win; property: "animProgress"; from: 1; to: 0; duration: 260; easing.type: Easing.InCubic }

    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                win.staticWalls = []; win.engineWalls = []; win.liveWalls = []
                findStatic.running = true; findEngine.running = true; findLive.running = true
                colorProc.running  = false; colorProc.running = true
                win.configOpen = false
                openAnim.start()
                Qt.callLater(function() { keyItem.forceActiveFocus() })
            } else {
                closeAnim.start()
            }
        }
    }

    // ── Scan ─────────────────────────────────────────────────
    Process {
        id: findStatic; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => { var f=data.trim(); if(f.length>0){var a=win.staticWalls.slice();a.push(f);win.staticWalls=a} }}
    }
    Process {
        id: findEngine; running: false
        command: ["bash","-c","for d in ~/.steam/steam/steamapps/workshop/content/431960/*/; do id=$(basename \"$d\"); prev=$(ls \"${d}\"preview.* 2>/dev/null | head -1); echo \"$id|$prev\"; done 2>/dev/null"]
        stdout: SplitParser { onRead: data => { var l=data.trim(); if(l.length===0) return; var p=l.split("|"); var a=win.engineWalls.slice(); a.push({path:p[0], preview:p.length>1?p[1]:""}); win.engineWalls=a }}
    }
    Process {
        id: findLive; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => { var f=data.trim(); if(f.length>0){var a=win.liveWalls.slice();a.push(f);win.liveWalls=a} }}
    }

    // ── Apply ────────────────────────────────────────────────
    Process { id: applyStatic; running: false }
    Process { id: applyEngine; running: false }
    Process { id: applyLive;   running: false }
    Process { id: killEngine;  running: false; command: ["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null; true"] }
    Process { id: killLive;    running: false; command: ["bash","-c","pkill -f mpvpaper 2>/dev/null; true"] }

    Process {
        id: colorProc; running: false
        property int lc: 0
        property string imageToSample: ""
        command: ["bash", "-c",
            "wall=\"" + colorProc.imageToSample + "\"; " +
            "[ -z \"$wall\" ] && wall=$(swww query 2>/dev/null | grep -o 'image: .*' | sed 's/image: //' | head -1); " +
            "[ -z \"$wall\" ] && echo '0.06 0.06 0.12' && echo '0.10 0.08 0.18' && exit; " +
            "convert \"$wall\" -resize 50x50! +dither -colors 2 -format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null | head -2"]
        stdout: SplitParser {
            onRead: data => {
                var p=data.trim().split(" "); if(p.length<3) return
                var r=Math.min(parseFloat(p[0])*0.8,0.45), g=Math.min(parseFloat(p[1])*0.8,0.45), b=Math.min(parseFloat(p[2])*0.8,0.45)
                if(colorProc.lc===0){ win.gc1=Qt.rgba(r,g,b,0.55); AppState.accentColor=Qt.rgba(r,g,b,1.0); AppState.accentPill=Qt.rgba(r,g,b,0.30); AppState.accentBorder=Qt.rgba(r,g,b,0.18) }
                else { win.gc2=Qt.rgba(r,g,b,0.75); AppState.accentDark=Qt.rgba(r,g,b,0.90) }
                colorProc.lc++
            }
        }
        onRunningChanged: if (running) lc = 0
    }

    Timer {
        id: engineDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.engineWalls[win.engineIdx]; if (!w) return
            if (w.preview !== "") { applyStatic.command=["swww","img",w.preview,"--transition-type","fade","--transition-duration","0.4"]; applyStatic.running=false; applyStatic.running=true }
            applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",w.path]; applyEngine.running=false; applyEngine.running=true
            if (w.preview !== "") { colorProc.imageToSample=w.preview; colorProc.running=false; colorProc.running=true }
        }
    }
    Timer {
        id: liveDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.liveWalls[win.liveIdx]; if (!w) return
            applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",w]; applyLive.running=false; applyLive.running=true
        }
    }

    function applyStaticWall(idx) {
        if (idx<0||idx>=staticWalls.length) return
        AppState.staticWallIdx=idx; win.staticIdx=idx
        killEngine.running=false; killEngine.running=true
        killLive.running=false; killLive.running=true
        applyStatic.command=["swww","img",staticWalls[idx],"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
        applyStatic.running=false; applyStatic.running=true
        colorProc.imageToSample=""; colorProc.running=false; colorProc.running=true
    }
    function applyEngineWall(idx) {
        if (idx<0||idx>=engineWalls.length) return
        win.engineIdx=idx; killLive.running=false; killLive.running=true; engineDebounce.restart()
    }
    function applyLiveWall(idx) {
        if (idx<0||idx>=liveWalls.length) return
        AppState.liveWallIdx=idx; win.liveIdx=idx; killEngine.running=false; killEngine.running=true; liveDebounce.restart()
    }
    function applyCurrentWall(idx) {
        if      (activeCategory===0) applyEngineWall(idx)
        else if (activeCategory===1) applyStaticWall(idx)
        else                         applyLiveWall(idx)
    }
    function selectNext() { if(win.currentIdx < win.currentWalls.length-1){ applyCurrentWall(win.currentIdx+1); wallRow.scrollToIdx(win.currentIdx) } }
    function selectPrev() { if(win.currentIdx > 0){ applyCurrentWall(win.currentIdx-1); wallRow.scrollToIdx(win.currentIdx) } }

    // ── UI ───────────────────────────────────────────────────
    Item {
        id: panelRoot

        // Posição via x/y calculados (anchors dinâmicos não funcionam no Wayland)
        property real pw: screen ? screen.width * win.panelWidthRatio : 1200
        width:  pw
        height: win.panelHeight

        x: {
            if (win.panelPosition === "right") return (screen ? screen.width : 1920) - pw - 20
            return ((screen ? screen.width : 1920) - pw) / 2
        }
        y: {
            var sh = screen ? screen.height : 1080
            var ph = win.panelHeight
            if (win.panelPosition === "top")    return 20
            if (win.panelPosition === "bottom") return sh - ph - 20
            if (win.panelPosition === "right")  return (sh - ph) / 2
            return (sh - ph) / 2  // center
        }
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        opacity: win.animProgress
        transform: Translate { y: (1 - win.animProgress) * 40 }

        // Fundo pill
        Rectangle {
            anchors.fill: parent; radius: win.panelHeight / 2
            color: "transparent"; border.color: win.cRm; border.width: 1; antialiasing: true
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: Qt.rgba(win.gc1.r, win.gc1.g, win.gc1.b, 0.18)
            }
        }

        // Teclado
        Item {
            id: keyItem; anchors.fill: parent; focus: true
            Keys.onEscapePressed:  AppState.toggleWallpaper()
            Keys.onUpPressed:    { win.activeCategory=(win.activeCategory+win.catNames.length-1)%win.catNames.length; wallRow.scrollToIdx(win.currentIdx) }
            Keys.onDownPressed:  { win.activeCategory=(win.activeCategory+1)%win.catNames.length; wallRow.scrollToIdx(win.currentIdx) }
            Keys.onLeftPressed:  win.selectPrev()
            Keys.onRightPressed: win.selectNext()
            Keys.onReturnPressed: win.applyCurrentWall(win.currentIdx)
            Keys.onEnterPressed:  win.applyCurrentWall(win.currentIdx)
        }

        // Indicador de categoria (pontos) — esquerda
        Column {
            anchors.left: parent.left
            anchors.leftMargin: win.panelHeight * 0.3
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: win.catNames
                delegate: Rectangle {
                    property bool act: index === win.activeCategory
                    width: act ? 18 : 6; height: 6; radius: 3
                    color: act ? win.cAc : Qt.rgba(1,1,1,0.25)
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    MouseArea { anchors.fill: parent; onClicked: { win.activeCategory=index; wallRow.scrollToIdx(win.currentIdx) } }
                }
            }
        }

        // Thumbnails
        Item {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.leftMargin:  win.panelHeight * 0.45
            anchors.rightMargin: win.panelHeight * 0.45
            clip: true

            ListView {
                id: wallRow; anchors.fill: parent
                orientation: ListView.Horizontal; spacing: 12; clip: true
                model: win.currentWalls; currentIndex: win.currentIdx

                function scrollToIdx(idx) {
                    var t=idx*(win.thumbW+spacing)-width/2+win.thumbW/2
                    scrollAnim.to=Math.max(0,Math.min(t,contentWidth-width)); scrollAnim.restart()
                }
                NumberAnimation on contentX { id: scrollAnim; duration: 400; easing.type: Easing.OutCubic }

                delegate: Item {
                    id: card; width: win.thumbW; height: wallRow.height
                    property bool isActive: index === win.currentIdx
                    scale:   isActive ? 1.0 : 0.92
                    opacity: isActive ? 1.0 : 0.65
                    Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Rectangle {
                        anchors.fill: parent; radius: 20; clip: true; color: Qt.rgba(0,0,0,0.3)
                        AnimatedImage {
                            anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                            smooth: true; asynchronous: true; playing: true
                            source: {
                                if (win.activeCategory===1) return "file://"+modelData
                                if (win.activeCategory===0) return modelData.preview!=="" ? "file://"+modelData.preview : ""
                                var base=modelData.replace(/.*\//,"").replace(/\.[^.]+$/,"")
                                return "file:///home/shira/.cache/qs_mpv_thumb_"+base+".jpg"
                            }
                            opacity: status===Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                        // Gradiente nome
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 32; color: "transparent"
                            gradient: Gradient { orientation: Gradient.Vertical
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: Qt.rgba(0,0,0,0.7) }
                            }
                            Text {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 8; bottomMargin: 6 }
                                text: win.activeCategory===0 ? (modelData.path||"") : modelData.replace(/.*\//,"").replace(/\.[^.]+$/,"")
                                font.pixelSize: 10; color: Qt.rgba(1,1,1,0.85); elide: Text.ElideRight
                            }
                        }
                        // Borda ativa
                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "transparent"
                            border.color: card.isActive ? win.cAc : Qt.rgba(1,1,1,0.10)
                            border.width: card.isActive ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: win.applyCurrentWall(index) }
                }
                Text {
                    visible: wallRow.count===0; anchors.centerIn: parent
                    text: "Nenhum wallpaper encontrado"; color: Qt.rgba(1,1,1,0.25); font.pixelSize: 12
                }
            }
        }

        // Botão ⚙
        Rectangle {
            id: cfgBtn
            anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.rightMargin: win.panelHeight*0.3 - width/2
            anchors.bottomMargin: -height/2
            width: 32; height: 32; radius: 16; antialiasing: true
            color: win.configOpen ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.30) : Qt.rgba(1,1,1,0.08)
            border.color: win.configOpen ? win.cAc : win.cRm; border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent; text: "⚙"; font.pixelSize: 14
                color: win.configOpen ? win.cAc : Qt.rgba(1,1,1,0.5)
                rotation: win.configOpen ? 45 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
            MouseArea { anchors.fill: parent; onClicked: win.configOpen = !win.configOpen }
        }

        // Painel config
        Rectangle {
            id: cfgPanel
            // Abre para cima normalmente, mas se painel estiver no topo, abre para baixo
            anchors.bottom: win.panelPosition==="top" ? undefined : parent.top
            anchors.top:    win.panelPosition==="top" ? parent.bottom : undefined
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: win.panelPosition==="top" ? 0 : 12
            anchors.topMargin:    win.panelPosition==="top" ? 12 : 0
            width: Math.min(560, panelRoot.pw - 40); height: cfgCol.implicitHeight + 32; radius: 18; antialiasing: true
            color: Qt.rgba(win.gc2.r, win.gc2.g, win.gc2.b, 0.55)
            border.color: win.cRm; border.width: 1
            opacity: win.configOpen ? 1 : 0; scale: win.configOpen ? 1 : 0.90
            transformOrigin: Item.Bottom; visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Column {
                id: cfgCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20; topMargin: 16 }
                spacing: 16

                Text { text: "CONFIGURAÇÕES DO SELETOR"; font.pixelSize: 9; font.letterSpacing: 1.5; color: Qt.rgba(1,1,1,0.4) }

                Column { width: parent.width; spacing: 8
                    Text { text: "Transição de wallpaper"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.7) }
                    Flow { width: parent.width; spacing: 6
                        Repeater {
                            model: ["grow","fade","wave","wipe","slide","outer","any","random","none"]
                            delegate: Rectangle {
                                property bool act: win.swwwTransition === modelData
                                width: tTxt.implicitWidth+20; height: 26; radius: 13
                                color: act ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.25) : Qt.rgba(1,1,1,0.07)
                                border.color: act ? win.cAc : "transparent"; border.width: 1
                                Text { id: tTxt; anchors.centerIn: parent; text: modelData; font.pixelSize: 11; color: act ? win.cAc : Qt.rgba(1,1,1,0.5) }
                                MouseArea { anchors.fill: parent; onClicked: win.swwwTransition = modelData }
                            }
                        }
                    }
                }

                Column { width: parent.width; spacing: 8
                    Text { text: "Posição do seletor"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.7) }
                    Row { spacing: 6
                        Repeater {
                            model: [{id:"center",label:"Centro"},{id:"top",label:"Topo"},{id:"bottom",label:"Baixo"},{id:"right",label:"Direita"}]
                            delegate: Rectangle {
                                property bool act: win.panelPosition === modelData.id
                                width: pTxt.implicitWidth+20; height: 26; radius: 13
                                color: act ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.25) : Qt.rgba(1,1,1,0.07)
                                border.color: act ? win.cAc : "transparent"; border.width: 1
                                Text { id: pTxt; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: act ? win.cAc : Qt.rgba(1,1,1,0.5) }
                                MouseArea { anchors.fill: parent; onClicked: win.panelPosition = modelData.id }
                            }
                        }
                    }
                }

                Row { spacing: 12; width: parent.width
                    Text { text: "Largura:"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.7); anchors.verticalCenter: parent.verticalCenter; width: 80 }
                    Slider {
                        id: wSlider; from: 0.40; to: 0.95; value: win.panelWidthRatio; width: parent.width-130
                        onValueChanged: win.panelWidthRatio = value
                        background: Rectangle { x: wSlider.leftPadding; y: wSlider.topPadding+wSlider.availableHeight/2-2; width: wSlider.availableWidth; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.15); Rectangle { width: wSlider.visualPosition*parent.width; height: parent.height; radius: parent.radius; color: win.cAc } }
                        handle: Rectangle { x: wSlider.leftPadding+wSlider.visualPosition*wSlider.availableWidth-8; y: wSlider.topPadding+wSlider.availableHeight/2-8; width: 16; height: 16; radius: 8; color: win.cAc }
                    }
                    Text { text: Math.round(win.panelWidthRatio*100)+"%"; font.pixelSize: 11; color: win.cAc; anchors.verticalCenter: parent.verticalCenter; width: 36 }
                }
            }
        }

        // Hints
        Row {
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.bottomMargin: 10; anchors.rightMargin: win.panelHeight*0.5
            spacing: 14
            Repeater {
                model: ["↑↓ Categoria", "←→ Navegar", "↵ Aplicar", "Esc Fechar"]
                delegate: Text { text: modelData; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.20) }
            }
        }
    }
}
