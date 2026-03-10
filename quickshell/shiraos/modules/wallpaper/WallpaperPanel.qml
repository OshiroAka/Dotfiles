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
    WlrLayershell.keyboardFocus: AppState.wallpaperOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors.top:    true
    anchors.right:  true
    margins.top:    16
    margins.right:  16

    color:         "transparent"
    implicitWidth:  animW
    implicitHeight: 720
    focusable:      true

    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    // ── State ──────────────────────────────────────────────────────────────
    property var staticWalls: []
    property var engineWalls: []
    property var liveWalls:   []

    property int staticIdx: AppState.staticWallIdx
    onStaticIdxChanged: AppState.staticWallIdx = win.staticIdx
    property int engineIdx: 0
    property int liveIdx:   AppState.liveWallIdx

    property var currentWalls: {
        if (AppState.activeWallRow === 0) return staticWalls
        if (AppState.activeWallRow === 1) return engineWalls
        return liveWalls
    }
    property int currentIdx: {
        if (AppState.activeWallRow === 0) return staticIdx
        if (AppState.activeWallRow === 1) return engineIdx
        return liveIdx
    }

    readonly property var catNames: ["Static", "Engine", "Live"]

    // ── Cores adaptativas do wallpaper ─────────────────────────────────────
    property color gc1: Qt.rgba(0.06, 0.06, 0.12, 2)
    property color gc2: Qt.rgba(0.10, 0.08, 0.18, 2)

    Process {
        id: colorProc; running: false
        property int lc: 0
        property string imageToSample: ""

        command: ["bash", "-c",
            "wall=\"" + colorProc.imageToSample + "\"; " +
            "[ -z \"$wall\" ] && wall=$(swww query 2>/dev/null | grep -o 'image: .*' | sed 's/image: //' | head -1); " +
            "[ -z \"$wall\" ] && echo '0.06 0.06 0.12' && echo '0.10 0.08 0.18' && exit; " +
            "convert \"$wall\" -resize 50x50! +dither -colors 2 " +
            "-format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null | head -2"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                if (p.length >= 3) {
                    var r = Math.min(parseFloat(p[0]) * 0.8, 0.45)
                    var g = Math.min(parseFloat(p[1]) * 0.8, 0.45)
                    var b = Math.min(parseFloat(p[2]) * 0.8, 0.45)
                    if (colorProc.lc === 0) win.gc1 = Qt.rgba(r, g, b, 1)
                    else                    win.gc2 = Qt.rgba(r, g, b, 1)
                    colorProc.lc++
                }
            }
        }
        onRunningChanged: if (running) lc = 0
    }

    // ── Animação: largura → altura ─────────────────────────────────────────
    property real animW: 0
    property real animH: 0   // altura real do panel em px

    SequentialAnimation {
        id: openAnim
        // Fase 1: expande largura
        NumberAnimation {
            target: win; property: "animW"
            from: 0; to: 180
            duration: 500; easing.type: Easing.OutExpo
        }
        // Fase 2: expande altura
        NumberAnimation {
            target: win; property: "animH"
            from: 0; to: 720
            duration: 800; easing.type: Easing.OutExpo
        }
        ScriptAction { script: keyItem.forceActiveFocus() }
    }

    SequentialAnimation {
        id: closeAnim
        // Fase 1: colapsa altura
        NumberAnimation {
            target: win; property: "animH"
            to: 0; duration: 2000; easing.type: Easing.InExpo
        }
        // Fase 2: colapsa largura
        NumberAnimation {
            target: win; property: "animW"
            to: 0; duration: 400; easing.type: Easing.InExpo
        }
    }

    // ── Triggers ───────────────────────────────────────────────────────────
    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                win.staticWalls = []; win.engineWalls = []; win.liveWalls = []
                findStatic.running = true
                findEngine.running = true
                findLive.running   = true
                colorProc.running  = false
                colorProc.running  = true
                openAnim.start()
            } else {
                closeAnim.start()
            }
        }
    }

    onStaticWallsChanged: if (staticWalls.length > 0)
        Qt.callLater(function() { wallList.smoothScrollTo(win.currentIdx) })
    onLiveWallsChanged: if (liveWalls.length > 0)
        Qt.callLater(function() { wallList.smoothScrollTo(win.currentIdx) })

    // ── Scan ───────────────────────────────────────────────────────────────
    Process {
        id: findStatic; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => {
            var f=data.trim(); if(f.length>0){var a=win.staticWalls.slice();a.push(f);win.staticWalls=a}
        }}
    }
    Process {
        id: findEngine; running: false
        command: ["bash","-c",
            "for d in ~/.steam/steam/steamapps/workshop/content/431960/*/; do " +
            "id=$(basename \"$d\"); " +
            "prev=$(ls \"${d}\"preview.* 2>/dev/null | head -1); " +
            "echo \"$id|$prev\"; done 2>/dev/null"]
        stdout: SplitParser { onRead: data => {
            var l=data.trim(); if(l.length===0) return
            var p=l.split("|"); var a=win.engineWalls.slice()
            a.push({path:p[0], preview:p.length>1?p[1]:""})
            win.engineWalls=a
        }}
    }
    Process {
        id: findLive; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => {
            var f=data.trim(); if(f.length>0){var a=win.liveWalls.slice();a.push(f);win.liveWalls=a}
        }}
    }

    // ── Apply ──────────────────────────────────────────────────────────────
    Process { id: applyStatic; running: false }
    Process { id: applyEngine; running: false }
    Process { id: applyLive;   running: false }
    Process { id: killEngine;  running: false
        command: ["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null; true"] }
    Process { id: killLive; running: false
        command: ["bash","-c","pkill -f mpvpaper 2>/dev/null; true"] }

    Timer {
        id: engineDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.engineWalls[win.engineIdx]; if (!w) return
            if (w.preview !== "") {
                applyStatic.command=["swww","img",w.preview,"--transition-type","fade","--transition-duration","0.4"]
                applyStatic.running=false; applyStatic.running=true
            }
            applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",w.path]
            applyEngine.running=false; applyEngine.running=true
            if (w.preview !== "") { colorProc.imageToSample=w.preview; colorProc.running=false; colorProc.running=true }
        }
    }
    Timer {
        id: liveDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.liveWalls[win.liveIdx]; if (!w) return
            applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",w]
            applyLive.running=false; applyLive.running=true
            var base=w.replace(/.*\//,"").replace(/\.[^.]+$/,"")
            colorProc.imageToSample="/home/oshiro/.cache/qs_mpv_thumb_"+base+".jpg"
            colorProc.running=false; colorProc.running=true
        }
    }

    function applyStaticWall(idx) {
        if (idx<0||idx>=staticWalls.length) return
        AppState.staticWallIdx=idx; win.staticIdx=idx
        killEngine.running=false; killEngine.running=true
        killLive.running=false;   killLive.running=true
        applyStatic.command=["swww","img",staticWalls[idx],
            "--transition-type","grow","--transition-duration","1","--transition-fps","60"]
        applyStatic.running=false; applyStatic.running=true
        colorProc.imageToSample=""; colorProc.running=false; colorProc.running=true
    }
    function applyEngineWall(idx) {
        if (idx<0||idx>=engineWalls.length) return
        win.engineIdx=idx
        killLive.running=false; killLive.running=true
        engineDebounce.restart()
    }
    function applyLiveWall(idx) {
        if (idx<0||idx>=liveWalls.length) return
        AppState.liveWallIdx=idx; win.liveIdx=idx
        wallList.smoothScrollTo(win.currentIdx)
        killEngine.running=false; killEngine.running=true
        liveDebounce.restart()
    }
    function applyCurrentWall(idx) {
        if      (AppState.activeWallRow===0) applyStaticWall(idx)
        else if (AppState.activeWallRow===1) applyEngineWall(idx)
        else                                 applyLiveWall(idx)
    }

    // ── UI ─────────────────────────────────────────────────────────────────
    // Panel cresce de cima para baixo via height animado
    Item {
        id: panel
        anchors.top:   parent.top
        anchors.right:  parent.right
        width:  win.animW
        height: win.animH
        clip:   true

        Rectangle {
            anchors.fill: parent; radius: 16
            color: "transparent"
            border.color: Qt.rgba(1,1,1,0.09); border.width: 1

            // Gradiente adaptativo ao wallpaper
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(win.gc1.r, win.gc1.g, win.gc1.b, 0.90) }
                    GradientStop { position: 1.0; color: Qt.rgba(win.gc2.r, win.gc2.g, win.gc2.b, 0.90) }
                }
                Behavior on gradient { }
            }
        }

        // Conteúdo tem altura total — o clip do panel esconde o resto
        Item {
            id: content
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 720

            Item {
                id: keyItem
                anchors.fill: parent; focus: true
                Keys.onEscapePressed: AppState.toggleWallpaper()
                Keys.onLeftPressed: {
                    AppState.activeWallRow = (AppState.activeWallRow + 2) % 3
                    wallList.smoothScrollTo(win.currentIdx)
                }
                Keys.onRightPressed: {
                    AppState.activeWallRow = (AppState.activeWallRow + 1) % 3
                    wallList.smoothScrollTo(win.currentIdx)
                }
                Keys.onUpPressed: {
                    var idx = win.currentIdx - 1
                    if (idx >= 0) { win.applyCurrentWall(idx); wallList.smoothScrollTo(win.currentIdx) }
                }
                Keys.onDownPressed: {
                    var idx = win.currentIdx + 1
                    if (idx < win.currentWalls.length) { win.applyCurrentWall(idx); wallList.smoothScrollTo(win.currentIdx) }
                }
            }

            Column {
                anchors.fill:    parent
                anchors.margins: 10
                spacing:         8

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8; height: 24
                    Text {
                        text: "\u2039"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { AppState.activeWallRow=(AppState.activeWallRow+2)%3; wallList.smoothScrollTo(win.currentIdx) }
                        }
                    }
                    Text {
                        text: win.catNames[AppState.activeWallRow]
                        color: "white"; font.pixelSize: 12; font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "\u203a"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { AppState.activeWallRow=(AppState.activeWallRow+1)%3; wallList.smoothScrollTo(win.currentIdx) }
                        }
                    }
                }

                ListView {
                    id: wallList
                    width:  parent.width
                    height: parent.height - 32
                    clip:   true; spacing: 8
                    model: AppState.activeWallRow===0 ? win.staticWalls
                         : AppState.activeWallRow===1 ? win.engineWalls
                         : win.liveWalls
                    currentIndex: win.currentIdx
                    property real thumbH: (height - 32) / 5

                    // Scroll suave via contentY animado
                    NumberAnimation on contentY {
                        id: scrollAnim
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                    function smoothScrollTo(idx) {
                        var target = idx * (thumbH + spacing) - (height / 2) + (thumbH / 2)
                        target = Math.max(0, Math.min(target, contentHeight - height))
                        scrollAnim.to = target
                        scrollAnim.restart()
                    }

                    delegate: Item {
                        id: card
                        width: wallList.width; height: wallList.thumbH
                        property bool isActive: index === win.currentIdx
                        scale:   isActive ? 1.0 : 0.94
                        opacity: isActive ? 1.0 : 0.55
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent; radius: 12
                            color: "transparent"; clip: true

                            Image {
                                anchors.fill: parent
                                source: {
                                    if (AppState.activeWallRow===0) return "file://"+modelData
                                    if (AppState.activeWallRow===1) return modelData.preview!=="" ? "file://"+modelData.preview : ""
                                    var base=modelData.replace(/.*\//,"").replace(/\.[^.]+$/,"")
                                    return "file:///home/oshiro/.cache/qs_mpv_thumb_"+base+".jpg"
                                }
                                fillMode: Image.PreserveAspectCrop
                                smooth: true; asynchronous: true
                                opacity: status===Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: AppState.activeWallRow > 0
                                text: AppState.activeWallRow===1 ? "🎬" : "🎥"
                                font.pixelSize: 24; opacity: 0.5
                            }

                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: card.isActive ? Qt.rgba(1,1,1,0.85) : Qt.rgba(1,1,1,0.10)
                                border.width: card.isActive ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: win.applyCurrentWall(index) }
                    }

                    Text {
                        visible: wallList.count === 0
                        anchors.centerIn: parent
                        text: "Vazio"; color: Qt.rgba(1,1,1,0.25); font.pixelSize: 10
                    }
                }
            }
        }
    }
}
