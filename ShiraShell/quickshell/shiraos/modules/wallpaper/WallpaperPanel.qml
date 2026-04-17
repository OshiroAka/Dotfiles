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
    anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
    color: "transparent"; focusable: true

    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    // ── Geometry ─────────────────────────────────────────────
    property bool   isVertical:     panelPosition === "right" || panelPosition === "left"
    property real   panelThick:     210          // pill thickness (height for H, width for V)
    property real   panelSpan:      0.75         // ratio of screen span
    property int    thumbRadius:    24
    property int    thumbW:         200          // card width  (horizontal mode)
    property int    thumbH:         155          // card height (vertical mode)
    property bool   configOpen:     false
    property string swwwTransition: "grow"
    property string panelPosition:  "bottom"
    property bool   blurEnabled:    true
    property string selectorBg:     ""

    // pill dimensions
    property real pillW: isVertical ? panelThick : (screen ? screen.width  : 1920) * panelSpan
    property real pillH: isVertical ? (screen ? screen.height : 1080) * panelSpan : panelThick

    property real sw: screen ? screen.width  : 1920
    property real sh: screen ? screen.height : 1080

    property real pillX: {
        if (panelPosition === "right")  return sw - pillW - 20
        if (panelPosition === "left")   return 20
        return (sw - pillW) / 2
    }
    property real pillY: {
        if (panelPosition === "top")    return 20
        if (panelPosition === "bottom") return sh - pillH - 20
        return (sh - pillH) / 2
    }

    // ── Categories: 0=♥ 1=Engine 2=Static 3=MPV ─────────────
    property int activeCategory: 2
    readonly property var catNames: ["♥", "Engine", "Static", "MPV"]

    property var staticWalls:  []
    property var engineWalls:  []
    property var liveWalls:    []
    property var favorites:    []
    property int staticHl:     0
    property int engineHl:     0
    property int liveHl:       0
    property int favHl:        0

    property int highlightIdx: {
        if (activeCategory === 0) return favHl
        if (activeCategory === 1) return engineHl
        if (activeCategory === 2) return staticHl
        return liveHl
    }
    property var currentWalls: {
        if (activeCategory === 0) return favorites
        if (activeCategory === 1) return engineWalls
        if (activeCategory === 2) return staticWalls
        return liveWalls
    }

    property color gc1: AppState.accentPill   || Qt.rgba(0.06,0.06,0.12,0.55)
    property color gc2: AppState.accentDark   || Qt.rgba(0.04,0.04,0.10,0.85)
    property color cAc: AppState.accentColor  || Qt.rgba(0.55,0.70,1.00,1.00)
    property color cRm: AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25)

    // ── Open/Close anim ──────────────────────────────────────
    property real animProg: 0
    NumberAnimation { id: openAnim;  target: win; property: "animProg"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
    NumberAnimation { id: closeAnim; target: win; property: "animProg"; from: 1; to: 0; duration: 260; easing.type: Easing.InCubic }

    // ── Shimmer (diagonal brilho ao aplicar) ─────────────────
    property real shimmerProg: -0.5
    SequentialAnimation {
        id: shimmerAnim; loops: 1
        NumberAnimation { target: win; property: "shimmerProg"; from: -0.5; to: 1.5; duration: 900; easing.type: Easing.InOutSine }
        ScriptAction { script: win.shimmerProg = -0.5 }
    }

    // ── Shooter (rastro ao trocar posição) ───────────────────
    property real  shootProg:    0
    property bool  shootActive:  false
    property real  shootFromX:   0
    property real  shootFromY:   0
    property real  shootToX:     0
    property real  shootToY:     0

    SequentialAnimation {
        id: shootAnim
        NumberAnimation { target: win; property: "shootProg"; from: 0; to: 1; duration: 550; easing.type: Easing.OutExpo }
        ScriptAction { script: win.shootActive = false }
    }

    property string _prevPos: "bottom"
    onPanelPositionChanged: {
        win.shootFromX = win.pillX + win.pillW / 2
        win.shootFromY = win.pillY + win.pillH / 2
        // destination is new pillX/Y (after binding update, use Qt.callLater)
        Qt.callLater(function() {
            win.shootToX  = win.pillX + win.pillW / 2
            win.shootToY  = win.pillY + win.pillH / 2
            win.shootProg = 0
            win.shootActive = true
            shootAnim.restart()
        })
        win._prevPos = panelPosition
    }

    // ── Scan ─────────────────────────────────────────────────
    Process {
        id: findStatic; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => { var f=data.trim(); if(f) { var a=win.staticWalls.slice(); a.push(f); win.staticWalls=a } } }
    }
    Process {
        id: findEngine; running: false
        command: ["bash","-c","for d in ~/.steam/steam/steamapps/workshop/content/431960/*/; do id=$(basename \"$d\"); prev=$(ls \"${d}\"preview.* 2>/dev/null | head -1); echo \"$id|$prev\"; done 2>/dev/null"]
        stdout: SplitParser { onRead: data => { var l=data.trim(); if(!l) return; var p=l.split("|"); var a=win.engineWalls.slice(); a.push({path:p[0],preview:p[1]||""}); win.engineWalls=a } }
    }
    Process {
        id: findLive; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => { var f=data.trim(); if(f) { var a=win.liveWalls.slice(); a.push(f); win.liveWalls=a } } }
    }
    Process {
        id: findBg; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/WallpaperSelector -maxdepth 1 -type f 2>/dev/null | shuf | head -1"]
        stdout: SplitParser { onRead: data => { var f=data.trim(); if(f) win.selectorBg=f } }
    }

    // ── Apply ─────────────────────────────────────────────────
    Process { id: applyStatic; running: false }
    Process { id: applyEngine; running: false }
    Process { id: applyLive;   running: false }
    Process { id: killEngine;  running: false; command: ["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null; true"] }
    Process { id: killLive;    running: false; command: ["bash","-c","pkill -f mpvpaper 2>/dev/null; true"] }
    Process {
        id: colorProc; running: false
        property int lc: 0; property string img: ""
        command: ["bash","-c",
            "w=\""+colorProc.img+"\"; [ -z \"$w\" ] && w=$(swww query 2>/dev/null|grep -o 'image: .*'|sed 's/image: //'|head -1); "+
            "[ -z \"$w\" ] && echo '0.06 0.06 0.12' && echo '0.10 0.08 0.18' && exit; "+
            "convert \"$w\" -resize 50x50! +dither -colors 2 -format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null | head -2"]
        stdout: SplitParser {
            onRead: data => {
                var p=data.trim().split(" "); if(p.length<3) return
                var r=Math.min(parseFloat(p[0])*0.8,0.45),g=Math.min(parseFloat(p[1])*0.8,0.45),b=Math.min(parseFloat(p[2])*0.8,0.45)
                if(colorProc.lc===0){win.gc1=Qt.rgba(r,g,b,0.55);AppState.accentColor=Qt.rgba(r,g,b,1.0);AppState.accentPill=Qt.rgba(r,g,b,0.30);AppState.accentBorder=Qt.rgba(r,g,b,0.18)}
                else{win.gc2=Qt.rgba(r,g,b,0.85);AppState.accentDark=Qt.rgba(r,g,b,0.90)}
                colorProc.lc++
            }
        }
        onRunningChanged: if(running) lc=0
    }

    function _shimmer() { shimmerAnim.restart() }

    function applyStaticWall(idx) {
        if(idx<0||idx>=staticWalls.length) return
        AppState.staticWallIdx=idx; win.staticHl=idx
        killEngine.running=false; killEngine.running=true
        killLive.running=false; killLive.running=true
        applyStatic.command=["swww","img",staticWalls[idx],"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
        applyStatic.running=false; applyStatic.running=true
        colorProc.img=""; colorProc.running=false; colorProc.running=true
        _shimmer()
    }
    function applyEngineWall(idx) {
        if(idx<0||idx>=engineWalls.length) return
        win.engineHl=idx; killLive.running=false; killLive.running=true
        var w=engineWalls[idx]
        if(w.preview){applyStatic.command=["swww","img",w.preview,"--transition-type","fade","--transition-duration","0.4"];applyStatic.running=false;applyStatic.running=true}
        applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",w.path]; applyEngine.running=false; applyEngine.running=true
        if(w.preview){colorProc.img=w.preview;colorProc.running=false;colorProc.running=true}
        _shimmer()
    }
    function applyLiveWall(idx) {
        if(idx<0||idx>=liveWalls.length) return
        AppState.liveWallIdx=idx; win.liveHl=idx
        killEngine.running=false; killEngine.running=true
        applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",liveWalls[idx]]; applyLive.running=false; applyLive.running=true
        _shimmer()
    }
    function applyFavWall(idx) {
        if(idx<0||idx>=favorites.length) return
        win.favHl=idx
        killEngine.running=false; killEngine.running=true
        killLive.running=false; killLive.running=true
        applyStatic.command=["swww","img",favorites[idx],"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
        applyStatic.running=false; applyStatic.running=true
        colorProc.img=""; colorProc.running=false; colorProc.running=true
        _shimmer()
    }
    function applyCurrentWall() {
        var i=win.highlightIdx
        if(activeCategory===0) applyFavWall(i)
        else if(activeCategory===1) applyEngineWall(i)
        else if(activeCategory===2) applyStaticWall(i)
        else applyLiveWall(i)
    }
    function navigate(dir) {
        var n=Math.max(0,Math.min(win.highlightIdx+dir,win.currentWalls.length-1))
        if(activeCategory===0) win.favHl=n
        else if(activeCategory===1) win.engineHl=n
        else if(activeCategory===2) win.staticHl=n
        else win.liveHl=n
        wallList.scrollToIdx(n)
    }
    function wallPath(item) {
        if(typeof item==="string") return item
        if(item && item.path) return item.path
        return ""
    }
    function toggleFav() {
        var walls=win.currentWalls, idx=win.highlightIdx
        if(!walls.length) return
        var p=wallPath(walls[idx]); if(!p) return
        var f=win.favorites.slice(), fi=f.indexOf(p)
        if(fi>=0) f.splice(fi,1); else f.push(p)
        win.favorites=f
    }
    function isFav(item) { return win.favorites.indexOf(wallPath(item))>=0 }

    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if(AppState.wallpaperOpen) {
                win.staticWalls=[]; win.engineWalls=[]; win.liveWalls=[]
                findStatic.running=true; findEngine.running=true; findLive.running=true
                findBg.running=false; findBg.running=true
                colorProc.running=false; colorProc.running=true
                win.configOpen=false
                openAnim.start()
                Qt.callLater(function(){ keyItem.forceActiveFocus() })
            } else { closeAnim.start() }
        }
    }

    // ── UI ────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // ── Pill ────────────────────────────────────────────
        Item {
            id: pill
            x: win.pillX; y: win.pillY
            width: win.pillW; height: win.pillH
            Behavior on x      { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on y      { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width  { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            opacity: win.animProg
            transform: Translate {
                x: win.panelPosition==="right" ? (1-win.animProg)*50 : win.panelPosition==="left" ? -(1-win.animProg)*50 : 0
                y: win.panelPosition==="bottom"? (1-win.animProg)*50 : win.panelPosition==="top" ? -(1-win.animProg)*50 : 0
            }

            // Background pill
            Rectangle {
                anchors.fill: parent
                radius: Math.min(width,height) / 2
                color: "transparent"; border.color: win.cRm; border.width: 1; antialiasing: true; clip: true

                // Selector background image
                Image {
                    anchors.fill: parent
                    source: win.selectorBg ? "file://"+win.selectorBg : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.15; visible: source !== ""
                }
                // Glass
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: Qt.rgba(win.gc1.r, win.gc1.g, win.gc1.b, win.blurEnabled ? 0.30 : 0.65)
                }
            }

            // ── Keyboard ─────────────────────────────────────
            Item {
                id: keyItem; anchors.fill: parent; focus: true
                Keys.onEscapePressed: AppState.toggleWallpaper()
                Keys.onPressed: ev => {
                    var horiz = !win.isVertical
                    if(horiz) {
                        if(ev.key===Qt.Key_Up)    { win.activeCategory=(win.activeCategory+win.catNames.length-1)%win.catNames.length; wallList.scrollToIdx(win.highlightIdx) }
                        else if(ev.key===Qt.Key_Down)  { win.activeCategory=(win.activeCategory+1)%win.catNames.length; wallList.scrollToIdx(win.highlightIdx) }
                        else if(ev.key===Qt.Key_Left)  win.navigate(-1)
                        else if(ev.key===Qt.Key_Right) win.navigate(1)
                    } else {
                        if(ev.key===Qt.Key_Left)  { win.activeCategory=(win.activeCategory+win.catNames.length-1)%win.catNames.length; wallList.scrollToIdx(win.highlightIdx) }
                        else if(ev.key===Qt.Key_Right) { win.activeCategory=(win.activeCategory+1)%win.catNames.length; wallList.scrollToIdx(win.highlightIdx) }
                        else if(ev.key===Qt.Key_Up)    win.navigate(-1)
                        else if(ev.key===Qt.Key_Down)  win.navigate(1)
                    }
                    if(ev.key===Qt.Key_Return||ev.key===Qt.Key_Enter) win.applyCurrentWall()
                    if(ev.key===Qt.Key_Space) win.toggleFav()
                    ev.accepted=true
                }
            }

            // ── Category indicators ───────────────────────────
            // Horizontal: column on left
            Column {
                visible: !win.isVertical
                anchors.left: parent.left
                anchors.leftMargin: win.panelThick * 0.22
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Repeater {
                    model: win.catNames
                    delegate: Item {
                        width: 36; height: 36
                        property bool act: index === win.activeCategory
                        Rectangle {
                            visible: index !== 0
                            anchors.centerIn: parent
                            width: act ? 22 : 7; height: 7; radius: 3.5
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            visible: index === 0
                            anchors.centerIn: parent
                            text: "♥"; font.pixelSize: act ? 16 : 11
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { win.activeCategory=index; wallList.scrollToIdx(win.highlightIdx) } }
                    }
                }
            }
            // Vertical: row on top
            Row {
                visible: win.isVertical
                anchors.top: parent.top
                anchors.topMargin: win.panelThick * 0.22
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Repeater {
                    model: win.catNames
                    delegate: Item {
                        width: 32; height: 32
                        property bool act: index === win.activeCategory
                        Rectangle {
                            visible: index !== 0
                            anchors.centerIn: parent
                            width: 7; height: act ? 22 : 7; radius: 3.5
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color  { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            visible: index === 0
                            anchors.centerIn: parent
                            text: "♥"; font.pixelSize: act ? 16 : 11
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { win.activeCategory=index; wallList.scrollToIdx(win.highlightIdx) } }
                    }
                }
            }

            // ── Thumbnails ────────────────────────────────────
            Item {
                id: thumbArea
                anchors.fill: parent
                anchors.leftMargin:   win.isVertical ? 8                          : win.panelThick * 0.38
                anchors.rightMargin:  win.isVertical ? 8                          : win.panelThick * 0.12
                anchors.topMargin:    win.isVertical ? win.panelThick * 0.38      : 8
                anchors.bottomMargin: win.isVertical ? win.panelThick * 0.12      : 8
                clip: true

                ListView {
                    id: wallList
                    anchors.fill: parent
                    orientation: win.isVertical ? ListView.Vertical : ListView.Horizontal
                    spacing: 10; clip: true
                    model: win.currentWalls
                    currentIndex: win.highlightIdx

                    function scrollToIdx(idx) {
                        var stride = (win.isVertical ? win.thumbH : win.thumbW) + spacing
                        var dim    =  win.isVertical ? height : width
                        var thumb  =  win.isVertical ? win.thumbH : win.thumbW
                        var t = idx * stride - dim/2 + thumb/2
                        var maxC = win.isVertical ? (contentHeight - height) : (contentWidth - width)
                        if(win.isVertical) {
                            yAnim.to = Math.max(0, Math.min(t, maxC)); yAnim.restart()
                        } else {
                            xAnim.to = Math.max(0, Math.min(t, maxC)); xAnim.restart()
                        }
                    }
                    NumberAnimation on contentX { id: xAnim; duration: 380; easing.type: Easing.OutCubic }
                    NumberAnimation on contentY { id: yAnim; duration: 380; easing.type: Easing.OutCubic }

                    delegate: Item {
                        id: card
                        property bool isHl:  index === win.highlightIdx
                        property bool isFav: win.isFav(modelData)
                        property real cw: win.isVertical ? thumbArea.width - 16 : win.thumbW
                        property real ch: win.isVertical ? win.thumbH           : thumbArea.height - 16

                        width:  win.isVertical ? thumbArea.width : win.thumbW
                        height: win.isVertical ? win.thumbH + 10 : thumbArea.height

                        scale:   isHl ? 1.0 : 0.91
                        opacity: isHl ? 1.0 : 0.58
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Rectangle {
                            id: cardRect
                            x: (parent.width  - cw) / 2
                            y: (parent.height - ch) / 2
                            width: cw; height: ch
                            radius: win.thumbRadius
                            clip: true; antialiasing: true; color: Qt.rgba(0,0,0,0.3)

                            // Image
                            AnimatedImage {
                                anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                                smooth: true; asynchronous: true; playing: true
                                source: {
                                    if(win.activeCategory===0) return "file://"+modelData
                                    if(win.activeCategory===2) return "file://"+modelData
                                    if(win.activeCategory===1) return modelData.preview ? "file://"+modelData.preview : ""
                                    var b=modelData.replace(/.*\//,"").replace(/\.[^.]+$/,"")
                                    return "file:///home/shira/.cache/qs_mpv_thumb_"+b+".jpg"
                                }
                                opacity: status===Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }

                            // Name gradient
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                height: 34; color: "transparent"
                                gradient: Gradient { orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0,0,0,0.78) }
                                }
                                Text {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 7; bottomMargin: 5 }
                                    text: {
                                        if(win.activeCategory===1) return (modelData.path||"")
                                        return typeof modelData==="string" ? modelData.replace(/.*\//,"").replace(/\.[^.]+$/,"") : ""
                                    }
                                    font.pixelSize: 9; color: Qt.rgba(1,1,1,0.82); elide: Text.ElideRight
                                }
                            }

                            // Active border
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: card.isHl ? win.cAc : Qt.rgba(1,1,1,0.07)
                                border.width: card.isHl ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }

                            // ── Shimmer diagonal brilho ──────
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; clip: true; color: "transparent"
                                visible: card.isHl && shimmerAnim.running
                                Rectangle {
                                    width:  cardRect.width * 0.55
                                    height: cardRect.height * 2.8
                                    rotation: -42
                                    x: win.shimmerProg * (cardRect.width * 2.0) - width * 0.5
                                    y: -cardRect.height * 0.85
                                    gradient: Gradient { orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.35; color: Qt.rgba(1,1,1,0.0) }
                                        GradientStop { position: 0.50; color: Qt.rgba(1,1,1,0.28) }
                                        GradientStop { position: 0.65; color: Qt.rgba(1,1,1,0.0) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }

                            // Fav indicator
                            Text {
                                visible: card.isFav
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 7
                                text: "♥"; font.pixelSize: 13; color: win.cAc
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if(win.activeCategory===0) win.favHl=index
                                else if(win.activeCategory===1) win.engineHl=index
                                else if(win.activeCategory===2) win.staticHl=index
                                else win.liveHl=index
                                win.applyCurrentWall()
                                wallList.scrollToIdx(index)
                            }
                        }
                    }

                    Text {
                        visible: wallList.count===0; anchors.centerIn: parent
                        text: win.activeCategory===0
                            ? "Nenhum favorito\nPressione Space para adicionar"
                            : "Nenhum wallpaper encontrado"
                        color: Qt.rgba(1,1,1,0.22); font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; width: parent.width - 40
                    }
                }
            }

            // ── Botão ⚙ — sempre vira para o centro ──────────
            Rectangle {
                id: cfgBtn
                z: 10
                width: 32; height: 32; radius: 16; antialiasing: true
                color: win.configOpen ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.30) : Qt.rgba(1,1,1,0.08)
                border.color: win.configOpen ? win.cAc : win.cRm; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                // X: facing center
                x: {
                    if(win.panelPosition==="right") return -width/2 - 4            // left edge (center side)
                    if(win.panelPosition==="left")  return pill.width - width/2 + 4 // right edge (center side)
                    // horizontal: bottom-right of pill
                    return pill.width - win.panelThick*0.22 - width/2
                }
                y: {
                    if(win.panelPosition==="top")   return pill.height - height/2 + 4  // bottom (center side)
                    if(win.panelPosition==="right"||win.panelPosition==="left")
                                                    return pill.height - height/2 - 4  // bottom of vertical pill
                    return -height/2 + 4                                                 // top (center side for bottom/center)
                }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent; text: "⚙"; font.pixelSize: 14
                    color: win.configOpen ? win.cAc : Qt.rgba(1,1,1,0.5)
                    rotation: win.configOpen ? 45 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                }
                MouseArea { anchors.fill: parent; onClicked: win.configOpen=!win.configOpen }
            }

            // ── Config panel — abre para o centro ─────────────
            Rectangle {
                id: cfgPanel
                z: 20
                property real pw2: Math.min(530, pill.width - 30)
                property real ph2: cfgCol.implicitHeight + 36
                width: pw2; height: ph2; radius: 18; antialiasing: true
                color: Qt.rgba(win.gc2.r, win.gc2.g, win.gc2.b, 0.96)
                border.color: win.cRm; border.width: 1
                opacity: win.configOpen ? 1 : 0
                scale:   win.configOpen ? 1 : 0.88
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Position: always opens toward screen center
                x: {
                    if(win.panelPosition==="right") return -pw2 - 8
                    if(win.panelPosition==="left")  return pill.width + 8
                    return pill.width/2 - pw2/2
                }
                y: {
                    if(win.panelPosition==="top")                                     return pill.height + 8
                    if(win.panelPosition==="right"||win.panelPosition==="left")       return pill.height - ph2
                    return -ph2 - 8
                }
                transformOrigin: {
                    if(win.panelPosition==="top")   return Item.Top
                    if(win.panelPosition==="right") return Item.Right
                    if(win.panelPosition==="left")  return Item.Left
                    return Item.Bottom
                }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Column {
                    id: cfgCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20; topMargin: 16 }
                    spacing: 14

                    Text { text: "CONFIGURAÇÕES DO SELETOR"; font.pixelSize: 9; font.letterSpacing: 1.5; color: Qt.rgba(1,1,1,0.38) }

                    // Transição
                    Column { width: parent.width; spacing: 6
                        Text { text: "Transição swww"; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.6) }
                        Flow { width: parent.width; spacing: 5
                            Repeater {
                                model: ["grow","fade","wave","wipe","slide","outer","any","random","none"]
                                delegate: Rectangle {
                                    property bool act: win.swwwTransition===modelData
                                    width: tTxt.implicitWidth+18; height: 24; radius: 12
                                    color: act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.25):Qt.rgba(1,1,1,0.06)
                                    border.color: act?win.cAc:"transparent"; border.width:1
                                    Text{id:tTxt;anchors.centerIn:parent;text:modelData;font.pixelSize:10;color:act?win.cAc:Qt.rgba(1,1,1,0.45)}
                                    MouseArea{anchors.fill:parent;onClicked:win.swwwTransition=modelData}
                                }
                            }
                        }
                    }

                    // Posição
                    Column { width: parent.width; spacing: 6
                        Text { text: "Posição do seletor"; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.6) }
                        Row { spacing: 5
                            Repeater {
                                model: [{id:"center",label:"Centro"},{id:"top",label:"Topo"},{id:"bottom",label:"Baixo"},{id:"right",label:"Direita"},{id:"left",label:"Esquerda"}]
                                delegate: Rectangle {
                                    property bool act: win.panelPosition===modelData.id
                                    width: pTxt.implicitWidth+18; height: 24; radius: 12
                                    color: act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.25):Qt.rgba(1,1,1,0.06)
                                    border.color: act?win.cAc:"transparent"; border.width:1
                                    Text{id:pTxt;anchors.centerIn:parent;text:modelData.label;font.pixelSize:10;color:act?win.cAc:Qt.rgba(1,1,1,0.45)}
                                    MouseArea{anchors.fill:parent;onClicked:win.panelPosition=modelData.id}
                                }
                            }
                        }
                    }

                    // Largura
                    Row { spacing: 10; width: parent.width
                        Text{text:"Largura";font.pixelSize:11;color:Qt.rgba(1,1,1,0.6);anchors.verticalCenter:parent.verticalCenter;width:60}
                        Slider {
                            id: wSlider; from: 0.35; to: 0.98; value: win.panelSpan; width: parent.width-110
                            onMoved: win.panelSpan = value
                            background: Rectangle { x:wSlider.leftPadding;y:wSlider.topPadding+wSlider.availableHeight/2-2;width:wSlider.availableWidth;height:4;radius:2;color:Qt.rgba(1,1,1,0.12)
                                Rectangle{width:wSlider.visualPosition*parent.width;height:parent.height;radius:parent.radius;color:win.cAc} }
                            handle: Rectangle { x:wSlider.leftPadding+wSlider.visualPosition*wSlider.availableWidth-8;y:wSlider.topPadding+wSlider.availableHeight/2-8;width:16;height:16;radius:8;color:win.cAc }
                        }
                        Text{text:Math.round(win.panelSpan*100)+"%";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:34}
                    }

                    // Borda radius
                    Row { spacing: 10; width: parent.width
                        Text{text:"Borda";font.pixelSize:11;color:Qt.rgba(1,1,1,0.6);anchors.verticalCenter:parent.verticalCenter;width:60}
                        Slider {
                            id: rSlider; from: 0; to: 80; value: win.thumbRadius; width: parent.width-110
                            onMoved: win.thumbRadius = Math.round(value)
                            background: Rectangle { x:rSlider.leftPadding;y:rSlider.topPadding+rSlider.availableHeight/2-2;width:rSlider.availableWidth;height:4;radius:2;color:Qt.rgba(1,1,1,0.12)
                                Rectangle{width:rSlider.visualPosition*parent.width;height:parent.height;radius:parent.radius;color:win.cAc} }
                            handle: Rectangle { x:rSlider.leftPadding+rSlider.visualPosition*rSlider.availableWidth-8;y:rSlider.topPadding+rSlider.availableHeight/2-8;width:16;height:16;radius:8;color:win.cAc }
                        }
                        Text{text:win.thumbRadius+"px";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:34}
                    }

                    // Blur toggle
                    Row { spacing: 12; width: parent.width; height: 28
                        Text{text:"Blur no painel";font.pixelSize:11;color:Qt.rgba(1,1,1,0.6);anchors.verticalCenter:parent.verticalCenter}
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:40;height:22;radius:11
                            color:win.blurEnabled?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.45):Qt.rgba(1,1,1,0.10)
                            Behavior on color{ColorAnimation{duration:150}}
                            Rectangle{
                                x:win.blurEnabled?parent.width-width-3:3; y:3; width:16;height:16;radius:8;color:"white"
                                Behavior on x{NumberAnimation{duration:150;easing.type:Easing.OutCubic}}
                            }
                            MouseArea{anchors.fill:parent;onClicked:win.blurEnabled=!win.blurEnabled}
                        }
                    }

                    Item { height: 2 }
                }
            }

            // Hints
            Row {
                visible: !win.isVertical
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 12; spacing: 14
                Repeater {
                    model: ["↑↓ Categoria","←→ Navegar","↵ Aplicar","Space ♥","Esc Fechar"]
                    delegate: Text { text: modelData; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.18) }
                }
            }
        }

        // ── Shooter particles ─────────────────────────────────
        Repeater {
            model: win.shootActive ? 10 : 0
            delegate: Rectangle {
                property real delay: index * 35
                property real prog: Math.max(0, Math.min(1, (win.shootProg - delay/550)))
                property real trailFade: Math.pow(1 - prog, 1.8)

                width:  3 + 5 * (1-prog); height: width; radius: width/2
                color:  win.cAc
                opacity: trailFade * 0.85
                x: win.shootFromX + (win.shootToX - win.shootFromX) * prog - width/2
                   + (index % 3 - 1) * 6 * (1-prog)
                y: win.shootFromY + (win.shootToY - win.shootFromY) * prog - height/2
                   + (Math.floor(index/3) - 1) * 6 * (1-prog)
            }
        }
    }
}
