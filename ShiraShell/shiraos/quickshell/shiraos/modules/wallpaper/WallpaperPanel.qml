import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.namespace:     "shiraos-wallpaper"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: AppState.wallpaperOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
    color: "transparent"; focusable: true
    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    // ── Config ───────────────────────────────────────────────
    property bool   isVertical:    panelPosition === "right" || panelPosition === "left"
    property real   panelThick:    210
    property real   panelSpan:     0.82
    property int    thumbRadius:   14
    property real   pillOpacity:   0.60
    property bool   configOpen:    false
    property int    cfgTab:        0
    property string swwwTransition: "grow"
    property string panelPosition:  "bottom"
    property string selectorBg:     ""
    property bool   useSelectorBg:  false

    property real pillW: isVertical ? panelThick : (screen ? screen.width  : 1920) * panelSpan
    property real pillH: isVertical ? (screen ? screen.height : 1080) * panelSpan : panelThick
    property real sw: screen ? screen.width  : 1920
    property real sh: screen ? screen.height : 1080
    property real pillX: {
        if (panelPosition === "right") return sw - pillW - 20
        if (panelPosition === "left")  return 20
        return (sw - pillW) / 2
    }
    property real pillY: {
        if (panelPosition === "top")    return 20
        if (panelPosition === "bottom") return sh - pillH - 20
        return (sh - pillH) / 2
    }

    // ── Categories ───────────────────────────────────────────
    property int activeCategory: 2
    readonly property var catNames: ["\u2665","Engine","Static","MPV"]
    property var staticWalls:  []
    property var engineWalls:  []
    property var liveWalls:    []
    property var favorites:    []
    property var selectorBgList: []
    property int staticHl: 0; property int engineHl: 0
    property int liveHl:   0; property int favHl:    0
    property var currentWalls: {
        if (activeCategory === 0) return favorites
        if (activeCategory === 1) return engineWalls
        if (activeCategory === 2) return staticWalls
        return liveWalls
    }
    property int highlightIdx: {
        if (activeCategory === 0) return favHl
        if (activeCategory === 1) return engineHl
        if (activeCategory === 2) return staticHl
        return liveHl
    }

    property color gc1: AppState.accentPill   || Qt.rgba(0.04,0.04,0.10,0.70)
    property color gc2: AppState.accentDark   || Qt.rgba(0.02,0.02,0.08,0.98)
    property color cAc: AppState.accentColor  || Qt.rgba(0.55,0.70,1.00,1.00)
    property color cRm: AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.20)

    // ── Animations ───────────────────────────────────────────
    property real animProg: 0
    NumberAnimation { id: openAnim;  target: win; property: "animProg"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
    NumberAnimation { id: closeAnim; target: win; property: "animProg"; from: 1; to: 0; duration: 260; easing.type: Easing.InCubic }

    property real shimmerProg: -0.5
    SequentialAnimation {
        id: shimmerAnim
        NumberAnimation { target: win; property: "shimmerProg"; from: -0.5; to: 1.5; duration: 800; easing.type: Easing.InOutSine }
        ScriptAction { script: win.shimmerProg = -0.5 }
    }

    property real shootProg: 0; property bool shootActive: false
    property real shootFX: 0;  property real shootFY: 0
    property real shootTX: 0;  property real shootTY: 0
    SequentialAnimation {
        id: shootAnim
        NumberAnimation { target: win; property: "shootProg"; from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo }
        ScriptAction { script: win.shootActive = false }
    }
    onPanelPositionChanged: {
        win.shootFX = win.pillX + win.pillW / 2
        win.shootFY = win.pillY + win.pillH / 2
        Qt.callLater(function() {
            win.shootTX = win.pillX + win.pillW / 2
            win.shootTY = win.pillY + win.pillH / 2
            win.shootProg = 0; win.shootActive = true; shootAnim.restart()
        })
    }

    // ── Processes ────────────────────────────────────────────
    Process { id: findStatic; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: function(data) { var f=data.trim(); if(f){var a=win.staticWalls.slice();a.push(f);win.staticWalls=a} } }
    }
    Process { id: findEngine; running: false
        command: ["bash","-c","cd ~/.steam/steam/steamapps/workshop/content/431960 2>/dev/null||exit; for d in */; do id=${d%/}; prev=$(ls ${d}preview.* 2>/dev/null|head -1); printf '%s|%s\n' $id $prev; done"]
        stdout: SplitParser { onRead: function(data) { var l=data.trim(); if(!l) return; var p=l.split("|"); var a=win.engineWalls.slice(); a.push({path:p[0],preview:p[1]||""}); win.engineWalls=a } }
    }
    Process { id: findLive; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: function(data) { var f=data.trim(); if(f){var a=win.liveWalls.slice();a.push(f);win.liveWalls=a} } }
    }
    Process { id: findBgList; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/WallpaperSelector -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: function(data) { var f=data.trim(); if(f){var a=win.selectorBgList.slice();a.push(f);win.selectorBgList=a} } }
    }
    Process { id: applyStatic; running: false }
    Process { id: applyEngine; running: false }
    Process { id: applyLive;   running: false }
    Process { id: killEngine;  running: false; command: ["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null; true"] }
    Process { id: killLive;    running: false; command: ["bash","-c","pkill -f mpvpaper 2>/dev/null; true"] }
    Process { id: colorProc;   running: false
        property int    lc:  0
        property string img: ""
        command: ["bash","-c",
            "w=\""+colorProc.img+"\"; [ -z \"$w\" ] && w=$(swww query 2>/dev/null|grep -o 'image: .*'|sed 's/image: //'|head -1); "+
            "[ -z \"$w\" ] && echo '0.06 0.06 0.12' && echo '0.10 0.08 0.18' && exit; "+
            "convert \"$w\" -resize 50x50! +dither -colors 2 -format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null | head -2"]
        stdout: SplitParser {
            onRead: function(data) {
                var p=data.trim().split(" "); if(p.length<3) return
                var r=Math.min(parseFloat(p[0])*0.8,0.45),g=Math.min(parseFloat(p[1])*0.8,0.45),b=Math.min(parseFloat(p[2])*0.8,0.45)
                if(colorProc.lc===0){win.gc1=Qt.rgba(r,g,b,0.55);AppState.accentColor=Qt.rgba(r,g,b,1.0);AppState.accentPill=Qt.rgba(r,g,b,0.30);AppState.accentBorder=Qt.rgba(r,g,b,0.18)}
                else{win.gc2=Qt.rgba(r,g,b,0.95);AppState.accentDark=Qt.rgba(r,g,b,0.90)}
                colorProc.lc++
            }
        }
        onRunningChanged: if (running) lc = 0
    }

    // ── Logic ────────────────────────────────────────────────
    function navigate(dir) {
        var n = Math.max(0, Math.min(win.highlightIdx + dir, win.currentWalls.length - 1))
        if      (activeCategory === 0) win.favHl    = n
        else if (activeCategory === 1) win.engineHl = n
        else if (activeCategory === 2) win.staticHl = n
        else                           win.liveHl   = n
        wallList.scrollToIdx(n)
    }
    function wallPath(item) {
        return typeof item === "string" ? item : (item && item.path ? item.path : "")
    }
    function isFav(item) {
        var p = wallPath(item)
        for (var i = 0; i < win.favorites.length; i++) {
            if (win.favorites[i].applyPath === p) return true
        }
        return activeCategory === 0
    }
    function toggleFav() {
        var walls = win.currentWalls
        var idx   = win.highlightIdx
        if (activeCategory === 0) {
            var f0 = win.favorites.slice(); f0.splice(idx, 1); win.favorites = f0; return
        }
        var item = walls[idx]
        var obj
        if (activeCategory === 2) {
            var sp = typeof item==="string" ? item : (item.path||"")
            obj = {dispPath:sp, applyType:"static", applyPath:sp, previewPath:sp}
        } else if (activeCategory === 1) {
            obj = {dispPath:item.preview||"", applyType:"engine", applyPath:item.path||"", previewPath:item.preview||""}
        } else {
            var lp = typeof item==="string" ? item : (item.path||"")
            obj = {dispPath:lp, applyType:"live", applyPath:lp, previewPath:lp}
        }
        var f2 = win.favorites.slice()
        var ex = false
        for (var i2 = 0; i2 < f2.length; i2++) {
            if (f2[i2].applyPath === obj.applyPath) { f2.splice(i2,1); ex=true; break }
        }
        if (!ex) f2.push(obj)
        win.favorites = f2
    }
    function doApply(item, cat) {
        if (cat === 0) {
            var tp = item.applyType || "static"
            if (tp === "static") {
                killEngine.running=false; killEngine.running=true
                killLive.running=false;   killLive.running=true
                applyStatic.command=["swww","img",item.applyPath,"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
                applyStatic.running=false; applyStatic.running=true
                colorProc.img=item.applyPath; colorProc.running=false; colorProc.running=true
            } else if (tp === "engine") {
                killLive.running=false; killLive.running=true
                if(item.previewPath){applyStatic.command=["swww","img",item.previewPath,"--transition-type","fade","--transition-duration","0.4"];applyStatic.running=false;applyStatic.running=true}
                applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",item.applyPath]
                applyEngine.running=false; applyEngine.running=true
                if(item.previewPath){colorProc.img=item.previewPath;colorProc.running=false;colorProc.running=true}
            } else {
                killEngine.running=false; killEngine.running=true
                applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",item.applyPath]
                applyLive.running=false; applyLive.running=true
            }
        } else if (cat === 2) {
            var p2 = typeof item==="string" ? item : (item.path||"")
            killEngine.running=false; killEngine.running=true
            killLive.running=false;   killLive.running=true
            applyStatic.command=["swww","img",p2,"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
            applyStatic.running=false; applyStatic.running=true
            colorProc.img=p2; colorProc.running=false; colorProc.running=true
        } else if (cat === 1) {
            killLive.running=false; killLive.running=true
            if(item.preview){applyStatic.command=["swww","img",item.preview,"--transition-type","fade","--transition-duration","0.4"];applyStatic.running=false;applyStatic.running=true}
            applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",item.path]
            applyEngine.running=false; applyEngine.running=true
            if(item.preview){colorProc.img=item.preview;colorProc.running=false;colorProc.running=true}
        } else {
            var lp2 = typeof item==="string" ? item : (item.path||"")
            killEngine.running=false; killEngine.running=true
            applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",lp2]
            applyLive.running=false; applyLive.running=true
        }
        shimmerAnim.restart()
    }
    function applyCurrentWall() {
        var walls = win.currentWalls
        var idx   = win.highlightIdx
        if (idx < 0 || idx >= walls.length) return
        doApply(walls[idx], win.activeCategory)
        if      (activeCategory === 0) win.favHl    = idx
        else if (activeCategory === 1) win.engineHl = idx
        else if (activeCategory === 2) win.staticHl = idx
        else                           win.liveHl   = idx
    }
    function thumbSrc(item, cat) {
        if (cat === 0) { var dp=item.dispPath||item.previewPath||""; return dp ? "file://"+dp : "" }
        if (cat === 2) return "file://"+(typeof item==="string"?item:(item.path||""))
        if (cat === 1) return item.preview ? "file://"+item.preview : ""
        var b=(typeof item==="string"?item:(item.path||"")).replace(/.*\//,"").replace(/\.[^.]+$/,"")
        return "file:///home/shira/.cache/qs_mpv_thumb_"+b+".jpg"
    }
    function thumbLabel(item, cat) {
        if (cat === 0) { var p=item.applyPath||""; return p.replace(/.*\//,"").replace(/\.[^.]+$/,"") }
        if (cat === 1) return item.path||""
        var s=typeof item==="string"?item:(item.path||"")
        return s.replace(/.*\//,"").replace(/\.[^.]+$/,"")
    }

    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                win.staticWalls=[]; win.engineWalls=[]; win.liveWalls=[]; win.selectorBgList=[]
                findStatic.running=true; findEngine.running=true; findLive.running=true; findBgList.running=true
                colorProc.running=false; colorProc.running=true
                win.configOpen=false; win.cfgTab=0
                openAnim.start()
                Qt.callLater(function() { keyItem.forceActiveFocus() })
            } else {
                closeAnim.start()
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        Item {
            id: pill
            x: win.pillX; y: win.pillY; width: win.pillW; height: win.pillH
            Behavior on x      { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on y      { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width  { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            opacity: win.animProg
            transform: Translate {
                x: win.panelPosition==="right"?(1-win.animProg)*60:win.panelPosition==="left"?-(1-win.animProg)*60:0
                y: win.panelPosition==="bottom"?(1-win.animProg)*60:win.panelPosition==="top"?-(1-win.animProg)*60:0
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.min(width,height) / 2
                color: "transparent"; antialiasing: true; clip: true
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: Qt.rgba(win.gc1.r, win.gc1.g, win.gc1.b, win.pillOpacity)
                }
                Image {
                    anchors.fill: parent
                    source: (win.useSelectorBg && win.selectorBg) ? "file://"+win.selectorBg : ""
                    fillMode: Image.PreserveAspectCrop; opacity: 0.18; visible: status===Image.Ready
                }
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: "transparent"; border.color: win.cRm; border.width: 1
                }
            }

            // ── Keyboard ─────────────────────────────────────
            Item {
                id: keyItem; anchors.fill: parent; focus: true
                Keys.onEscapePressed: AppState.toggleWallpaper()
                Keys.onReturnPressed: win.applyCurrentWall()
                Keys.onEnterPressed:  win.applyCurrentWall()
                Keys.onUpPressed: {
                    if (!win.isVertical) {
                        win.activeCategory = (win.activeCategory + win.catNames.length - 1) % win.catNames.length
                        wallList.scrollToIdx(win.highlightIdx)
                    } else {
                        win.navigate(-1)
                    }
                }
                Keys.onDownPressed: {
                    if (!win.isVertical) {
                        win.activeCategory = (win.activeCategory + 1) % win.catNames.length
                        wallList.scrollToIdx(win.highlightIdx)
                    } else {
                        win.navigate(1)
                    }
                }
                Keys.onLeftPressed: {
                    if (!win.isVertical) {
                        win.navigate(-1)
                    } else {
                        win.activeCategory = (win.activeCategory + win.catNames.length - 1) % win.catNames.length
                        wallList.scrollToIdx(win.highlightIdx)
                    }
                }
                Keys.onRightPressed: {
                    if (!win.isVertical) {
                        win.navigate(1)
                    } else {
                        win.activeCategory = (win.activeCategory + 1) % win.catNames.length
                        wallList.scrollToIdx(win.highlightIdx)
                    }
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Space) {
                        win.toggleFav()
                        event.accepted = true
                    }
                }
            }

            // Category dots
            Column {
                visible: !win.isVertical
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter; spacing: 10
                Repeater {
                    model: win.catNames
                    delegate: Item {
                        width: 30; height: 30
                        property bool act: index === win.activeCategory
                        Text {
                            visible: index === 0; anchors.centerIn: parent; text: "\u2665"
                            font.pixelSize: act ? 17 : 12
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Rectangle {
                            visible: index !== 0; anchors.centerIn: parent
                            width: act ? 20 : 6; height: 6; radius: 3
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { win.activeCategory=index; wallList.scrollToIdx(win.highlightIdx) } }
                    }
                }
            }
            Row {
                visible: win.isVertical
                anchors.top: parent.top; anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                Repeater {
                    model: win.catNames
                    delegate: Item {
                        width: 30; height: 30
                        property bool act: index === win.activeCategory
                        Text {
                            visible: index === 0; anchors.centerIn: parent; text: "\u2665"
                            font.pixelSize: act ? 17 : 12
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Rectangle {
                            visible: index !== 0; anchors.centerIn: parent
                            width: 6; height: act ? 20 : 6; radius: 3
                            color: act ? win.cAc : Qt.rgba(1,1,1,0.22)
                            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color  { ColorAnimation { duration: 160 } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { win.activeCategory=index; wallList.scrollToIdx(win.highlightIdx) } }
                    }
                }
            }

            // Thumbnails
            Item {
                anchors.fill: parent
                anchors.leftMargin:   win.isVertical ? 6  : 54
                anchors.rightMargin:  win.isVertical ? 6  : 50
                anchors.topMargin:    win.isVertical ? 58 : 6
                anchors.bottomMargin: 6
                clip: true

                ListView {
                    id: wallList; anchors.fill: parent
                    orientation: win.isVertical ? ListView.Vertical : ListView.Horizontal
                    spacing: 8; clip: true; model: win.currentWalls; currentIndex: win.highlightIdx

                    function scrollToIdx(idx) {
                        var stride = (win.isVertical ? (win.panelThick*0.55) : (win.pillH*1.58)) + spacing
                        var dim    =  win.isVertical ? height : width
                        var t      = idx * stride - dim/2 + stride/2
                        var maxC   = win.isVertical ? Math.max(0,contentHeight-height) : Math.max(0,contentWidth-width)
                        if (win.isVertical) { yA.to=Math.max(0,Math.min(t,maxC)); yA.restart() }
                        else               { xA.to=Math.max(0,Math.min(t,maxC)); xA.restart() }
                    }
                    NumberAnimation on contentX { id: xA; duration: 380; easing.type: Easing.OutCubic }
                    NumberAnimation on contentY { id: yA; duration: 380; easing.type: Easing.OutCubic }

                    delegate: Item {
                        id: card
                        property bool isHl: index === win.highlightIdx
                        property bool fav:  win.isFav(modelData)
                        property real cw: win.isVertical ? wallList.width-12 : Math.round(wallList.height*1.58)
                        property real ch: win.isVertical ? Math.round(win.panelThick*0.50) : wallList.height-12
                        width:  win.isVertical ? wallList.width : cw+10
                        height: win.isVertical ? ch+10 : wallList.height
                        scale:   isHl ? 1.0 : 0.89
                        opacity: isHl ? 1.0 : 0.52
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Rectangle {
                            id: cardRect
                            x: (parent.width-cw)/2; y: (parent.height-ch)/2
                            width: cw; height: ch; radius: win.thumbRadius
                            clip: true; antialiasing: true; color: Qt.rgba(0,0,0,0.35)
                            AnimatedImage {
                                anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                                smooth: true; asynchronous: true; playing: true
                                source: win.thumbSrc(modelData, win.activeCategory)
                                opacity: status===Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                height: 32; color: "transparent"
                                gradient: Gradient { orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0,0,0,0.82) }
                                }
                                Text {
                                    anchors { bottom:parent.bottom; left:parent.left; right:parent.right; margins:6; bottomMargin:5 }
                                    text: win.thumbLabel(modelData, win.activeCategory)
                                    font.pixelSize: 9; color: Qt.rgba(1,1,1,0.80); elide: Text.ElideRight
                                }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: card.isHl ? win.cAc : Qt.rgba(1,1,1,0.06)
                                border.width: card.isHl ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; clip: true; color: "transparent"
                                visible: card.isHl && shimmerAnim.running
                                Rectangle {
                                    width: cardRect.width*0.55; height: cardRect.height*3; rotation: -42
                                    x: win.shimmerProg*cardRect.width*2.2-width*0.5; y: -cardRect.height*0.9
                                    gradient: Gradient { orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0;  color: "transparent" }
                                        GradientStop { position: 0.40; color: Qt.rgba(1,1,1,0.00) }
                                        GradientStop { position: 0.50; color: Qt.rgba(1,1,1,0.30) }
                                        GradientStop { position: 0.60; color: Qt.rgba(1,1,1,0.00) }
                                        GradientStop { position: 1.0;  color: "transparent" }
                                    }
                                }
                            }
                            Text {
                                visible: card.fav
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 6
                                text: "\u2665"; font.pixelSize: 12; color: win.cAc
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if      (activeCategory===0) win.favHl    = index
                                else if (activeCategory===1) win.engineHl = index
                                else if (activeCategory===2) win.staticHl = index
                                else                         win.liveHl   = index
                                win.applyCurrentWall(); wallList.scrollToIdx(index)
                            }
                        }
                    }
                    Text {
                        visible: wallList.count === 0; anchors.centerIn: parent
                        text: win.activeCategory===0 ? "Nenhum favorito\nPressione Space \u2665" : "Nenhum wallpaper encontrado"
                        color: Qt.rgba(1,1,1,0.22); font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; width: 220
                    }
                }
            }

            // ⚙ button
            Rectangle {
                id: cfgBtn; z: 10; width: 32; height: 32; radius: 16; antialiasing: true
                color: win.configOpen ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.30) : Qt.rgba(1,1,1,0.08)
                border.color: win.configOpen ? win.cAc : win.cRm; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                x: {
                    if (win.panelPosition==="right") return -width-8
                    if (win.panelPosition==="left")  return pill.width+8
                    return pill.width-46
                }
                y: {
                    if (win.panelPosition==="right"||win.panelPosition==="left") return pill.height-height-10
                    if (win.panelPosition==="top") return pill.height+8
                    return -height-8
                }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Text { anchors.centerIn: parent; text: "\u2699"; font.pixelSize: 14
                    color: win.configOpen ? win.cAc : Qt.rgba(1,1,1,0.5)
                    rotation: win.configOpen ? 45 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                }
                MouseArea { anchors.fill: parent; onClicked: win.configOpen = !win.configOpen }
            }

            // Config panel
            Rectangle {
                id: cfgPanel; z: 20
                width: Math.min(500, pill.width-20)
                height: cfgInner.height + 58
                radius: 20; antialiasing: true
                color: Qt.rgba(0.03,0.03,0.09,0.98)
                border.color: Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.20); border.width: 1
                opacity: win.configOpen ? 1 : 0; scale: win.configOpen ? 1 : 0.88
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                x: {
                    if (win.panelPosition==="right") return -width-10
                    if (win.panelPosition==="left")  return pill.width+10
                    return (pill.width-width)/2
                }
                y: {
                    if (win.panelPosition==="top") return pill.height+10
                    if (win.panelPosition==="right"||win.panelPosition==="left") return pill.height-height
                    return -height-10
                }
                transformOrigin: {
                    if (win.panelPosition==="top")   return Item.Top
                    if (win.panelPosition==="right") return Item.Right
                    if (win.panelPosition==="left")  return Item.Left
                    return Item.Bottom
                }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Row {
                    id: tabRow; z: 1
                    anchors.top: parent.top; anchors.topMargin: 14
                    anchors.left: parent.left; anchors.leftMargin: 14
                    spacing: 5
                    Repeater {
                        model: ["Posi\u00e7\u00e3o","Apar\u00eancia","Fundo","Tamanhos"]
                        delegate: Rectangle {
                            property bool act: win.cfgTab === index
                            width: tabT.implicitWidth+18; height: 26; radius: 13
                            color: act ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.22) : Qt.rgba(1,1,1,0.06)
                            border.color: act ? win.cAc : "transparent"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: tabT; anchors.centerIn: parent; text: modelData; font.pixelSize: 10
                                color: act ? win.cAc : Qt.rgba(1,1,1,0.42) }
                            MouseArea { anchors.fill: parent; onClicked: win.cfgTab = index }
                        }
                    }
                }
                Rectangle {
                    anchors.top: tabRow.bottom; anchors.topMargin: 10
                    anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 14
                    height: 1; color: Qt.rgba(1,1,1,0.06)
                }

                Column {
                    id: cfgInner
                    anchors.top: tabRow.bottom; anchors.topMargin: 20
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 18; anchors.rightMargin: 18
                    spacing: 14

                    // ── Tab 0: Posição ────────────────────────
                    Column { visible: win.cfgTab===0; width: parent.width; spacing: 12
                        Text { text: "Posi\u00e7\u00e3o do seletor"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.45) }
                        Grid { columns: 3; spacing: 6; width: parent.width
                            Repeater {
                                model: [{i:"top",l:"\u2b06 Topo"},{i:"left",l:"\u2b05 Esq"},{i:"center",l:"\u29bf Centro"},
                                        {i:"right",l:"Dir \u27a1"},{i:"bottom",l:"\u2b07 Baixo"},{i:"",l:""}]
                                delegate: Rectangle {
                                    visible: modelData.i !== ""
                                    property bool act: win.panelPosition === modelData.i
                                    width: (cfgInner.width-12)/3; height: 34; radius: 12
                                    color: act ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.22) : Qt.rgba(1,1,1,0.06)
                                    border.color: act ? win.cAc : "transparent"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 11
                                        color: act ? win.cAc : Qt.rgba(1,1,1,0.45) }
                                    MouseArea { anchors.fill: parent; onClicked: win.panelPosition = modelData.i }
                                }
                            }
                        }
                        Text { text: "Transi\u00e7\u00e3o swww"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.45) }
                        Flow { width: parent.width; spacing: 5
                            Repeater {
                                model: ["grow","fade","wave","wipe","slide","outer","any","random","none"]
                                delegate: Rectangle {
                                    property bool act: win.swwwTransition === modelData
                                    width: tT.implicitWidth+14; height: 24; radius: 12
                                    color: act ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.22) : Qt.rgba(1,1,1,0.06)
                                    border.color: act ? win.cAc : "transparent"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text { id: tT; anchors.centerIn: parent; text: modelData; font.pixelSize: 10
                                        color: act ? win.cAc : Qt.rgba(1,1,1,0.42) }
                                    MouseArea { anchors.fill: parent; onClicked: win.swwwTransition = modelData }
                                }
                            }
                        }
                        Item { height: 4 }
                    }

                    // ── Tab 1: Aparência ──────────────────────
                    Column { visible: win.cfgTab===1; width: parent.width; spacing: 14
                        Text { text: "Opacidade do painel"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.45) }
                        Row { spacing: 10; width: parent.width
                        Item {
                            id: slOp; width: parent.width-46; height: 22
                            property real slFrom: 0.10; property real slTo: 0.98
                            property real slVal: win.pillOpacity
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 2.5
                                color: Qt.rgba(1,1,1,0.12)
                                Rectangle {
                                    width: Math.max(0,Math.min(1,(slOp.slVal-slOp.slFrom)/(slOp.slTo-slOp.slFrom)))*parent.width
                                    height: parent.height; radius: parent.radius; color: win.cAc
                                }
                            }
                            Rectangle {
                                property real pos: Math.max(0,Math.min(1,(slOp.slVal-slOp.slFrom)/(slOp.slTo-slOp.slFrom)))
                                x: pos*(slOp.width-width); anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9; color: win.cAc; antialiasing: true
                                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "white"; opacity: 0.9 }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                onPressed:         { var r=Math.max(0,Math.min(1,(mouseX-9)/(slOp.width-18))); slOp.slVal=slOp.slFrom+r*(slOp.slTo-slOp.slFrom); win.pillOpacity=slOp.slVal }
                                onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,(mouseX-9)/(slOp.width-18))); slOp.slVal=slOp.slFrom+r*(slOp.slTo-slOp.slFrom); win.pillOpacity=slOp.slVal } }
                            }
                        }
                            Text { text: Math.round(slOp.slVal*100)+"%"; font.pixelSize:10; color:win.cAc; anchors.verticalCenter:parent.verticalCenter; width:36 }
                        }
                        Text { text: "Espessura da pill"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.45) }
                        Row { spacing: 10; width: parent.width
                        Item {
                            id: slTh; width: parent.width-46; height: 22
                            property real slFrom: 140; property real slTo: 340
                            property real slVal: win.panelThick
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 2.5
                                color: Qt.rgba(1,1,1,0.12)
                                Rectangle {
                                    width: Math.max(0,Math.min(1,(slTh.slVal-slTh.slFrom)/(slTh.slTo-slTh.slFrom)))*parent.width
                                    height: parent.height; radius: parent.radius; color: win.cAc
                                }
                            }
                            Rectangle {
                                property real pos: Math.max(0,Math.min(1,(slTh.slVal-slTh.slFrom)/(slTh.slTo-slTh.slFrom)))
                                x: pos*(slTh.width-width); anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9; color: win.cAc; antialiasing: true
                                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "white"; opacity: 0.9 }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                onPressed:         { var r=Math.max(0,Math.min(1,(mouseX-9)/(slTh.width-18))); slTh.slVal=slTh.slFrom+r*(slTh.slTo-slTh.slFrom); win.panelThick=Math.round(slTh.slVal) }
                                onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,(mouseX-9)/(slTh.width-18))); slTh.slVal=slTh.slFrom+r*(slTh.slTo-slTh.slFrom); win.panelThick=Math.round(slTh.slVal) } }
                            }
                        }
                            Text { text: Math.round(slTh.slVal)+"px"; font.pixelSize:10; color:win.cAc; anchors.verticalCenter:parent.verticalCenter; width:36 }
                        }
                        Item { height: 4 }
                    }

                    // ── Tab 2: Fundo ──────────────────────────
                    Column { visible: win.cfgTab===2; width: parent.width; spacing: 12
                        Row { spacing: 12; height: 32
                            Text { text: "Imagem de fundo"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.55); anchors.verticalCenter: parent.verticalCenter }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width:40; height:22; radius:11
                                color: win.useSelectorBg ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.45) : Qt.rgba(1,1,1,0.10)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Rectangle { x:win.useSelectorBg?parent.width-width-3:3; y:3; width:16; height:16; radius:8; color:"white"
                                    Behavior on x { NumberAnimation { duration:150; easing.type:Easing.OutCubic } } }
                                MouseArea { anchors.fill: parent; onClicked: win.useSelectorBg = !win.useSelectorBg }
                            }
                        }
                        Text { font.pixelSize:9; color:Qt.rgba(1,1,1,0.30); wrapMode:Text.Wrap; width:parent.width
                            text: "~/Pictures/Wallpapers/WallpaperSelector/" }
                        Text { text: "Imagens ("+win.selectorBgList.length+")"; font.pixelSize:10; color:Qt.rgba(1,1,1,0.45) }
                        Flow { width: parent.width; spacing: 6
                            Repeater { model: win.selectorBgList
                                delegate: Rectangle {
                                    property bool cur: win.selectorBg === modelData
                                    width:68; height:44; radius:8; clip:true
                                    border.color: cur?win.cAc:"transparent"; border.width:2
                                    Image { anchors.fill:parent; source:"file://"+modelData; fillMode:Image.PreserveAspectCrop; smooth:true }
                                    MouseArea { anchors.fill:parent; onClicked:{ win.selectorBg=modelData; win.useSelectorBg=true } }
                                }
                            }
                            Text { visible:win.selectorBgList.length===0; text:"Nenhuma imagem"; font.pixelSize:10; color:Qt.rgba(1,1,1,0.25) }
                        }
                        Item { height: 4 }
                    }

                    // ── Tab 3: Tamanhos ───────────────────────
                    Column { visible: win.cfgTab===3; width: parent.width; spacing: 14
                        Text { text: "Largura do seletor"; font.pixelSize:10; color:Qt.rgba(1,1,1,0.45) }
                        Row { spacing:10; width:parent.width
                        Item {
                            id: slSp; width: parent.width-46; height: 22
                            property real slFrom: 0.30; property real slTo: 0.99
                            property real slVal: win.panelSpan
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 2.5
                                color: Qt.rgba(1,1,1,0.12)
                                Rectangle {
                                    width: Math.max(0,Math.min(1,(slSp.slVal-slSp.slFrom)/(slSp.slTo-slSp.slFrom)))*parent.width
                                    height: parent.height; radius: parent.radius; color: win.cAc
                                }
                            }
                            Rectangle {
                                property real pos: Math.max(0,Math.min(1,(slSp.slVal-slSp.slFrom)/(slSp.slTo-slSp.slFrom)))
                                x: pos*(slSp.width-width); anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9; color: win.cAc; antialiasing: true
                                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "white"; opacity: 0.9 }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                onPressed:         { var r=Math.max(0,Math.min(1,(mouseX-9)/(slSp.width-18))); slSp.slVal=slSp.slFrom+r*(slSp.slTo-slSp.slFrom); win.panelSpan=slSp.slVal }
                                onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,(mouseX-9)/(slSp.width-18))); slSp.slVal=slSp.slFrom+r*(slSp.slTo-slSp.slFrom); win.panelSpan=slSp.slVal } }
                            }
                        }
                            Text { text:Math.round(slSp.slVal*100)+"%"; font.pixelSize:10; color:win.cAc; anchors.verticalCenter:parent.verticalCenter; width:36 }
                        }
                        Text { text:"Borda dos thumbnails"; font.pixelSize:10; color:Qt.rgba(1,1,1,0.45) }
                        Row { spacing:10; width:parent.width
                        Item {
                            id: slRa; width: parent.width-46; height: 22
                            property real slFrom: 0; property real slTo: 80
                            property real slVal: win.thumbRadius
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 2.5
                                color: Qt.rgba(1,1,1,0.12)
                                Rectangle {
                                    width: Math.max(0,Math.min(1,(slRa.slVal-slRa.slFrom)/(slRa.slTo-slRa.slFrom)))*parent.width
                                    height: parent.height; radius: parent.radius; color: win.cAc
                                }
                            }
                            Rectangle {
                                property real pos: Math.max(0,Math.min(1,(slRa.slVal-slRa.slFrom)/(slRa.slTo-slRa.slFrom)))
                                x: pos*(slRa.width-width); anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9; color: win.cAc; antialiasing: true
                                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "white"; opacity: 0.9 }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                onPressed:         { var r=Math.max(0,Math.min(1,(mouseX-9)/(slRa.width-18))); slRa.slVal=slRa.slFrom+r*(slRa.slTo-slRa.slFrom); win.thumbRadius=Math.round(slRa.slVal) }
                                onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,(mouseX-9)/(slRa.width-18))); slRa.slVal=slRa.slFrom+r*(slRa.slTo-slRa.slFrom); win.thumbRadius=Math.round(slRa.slVal) } }
                            }
                        }
                            Text { text:win.thumbRadius+"px"; font.pixelSize:10; color:win.cAc; anchors.verticalCenter:parent.verticalCenter; width:36 }
                        }
                        Row { spacing:8; height:52
                            Text { text:"Preview:"; font.pixelSize:9; color:Qt.rgba(1,1,1,0.30); anchors.verticalCenter:parent.verticalCenter }
                            Rectangle { width:72; height:46; radius:win.thumbRadius; antialiasing:true
                                color:Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.18); border.color:win.cAc; border.width:1 }
                        }
                        Item { height: 4 }
                    }
                }
            }

            // Hints
            Row {
                visible: !win.isVertical
                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 12; spacing: 12
                Repeater {
                    model: ["\u2191\u2193 Cat","\u2190\u2192 Nav","\u23ce Aplicar","Space \u2665","Esc"]
                    delegate: Text { text:modelData; font.pixelSize:9; color:Qt.rgba(1,1,1,0.15) }
                }
            }
        }

        // Shooter particles
        Repeater {
            model: win.shootActive ? 14 : 0
            delegate: Rectangle {
                property real prog: Math.max(0, Math.min(1, win.shootProg - index*0.055))
                property real fade: Math.pow(1-prog, 2.2)
                width: 4+5*(1-prog); height: width; radius: width/2
                color: win.cAc; opacity: fade * 0.88
                x: win.shootFX + (win.shootTX-win.shootFX)*prog - width/2  + (index%4-1.5)*9*(1-prog)
                y: win.shootFY + (win.shootTY-win.shootFY)*prog - height/2 + (Math.floor(index/4)-1)*9*(1-prog)
            }
        }
    }
}
