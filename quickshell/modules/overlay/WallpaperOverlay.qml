import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import OshiroShell 1.0
import "../shared"

PanelWindow {
    id: win
    anchors.top: true
    anchors.left: true
    margins.top: 8
    margins.left: screen ? Math.round((screen.width - 860) / 2) : 510
    color: "transparent"
    implicitWidth: 860
    implicitHeight: 260
    visible: true
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppState.wallpaperOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    WaylandRegion { id: region }
    Item { id: wb; visible: false
        Component.onCompleted: Qt.callLater(function() {
            var w = wb.Window.window
            if (w) region.apply(w, 0, 0, 860, 260)
        })
    }

    property color gc1: Qt.rgba(0.06,0.06,0.12,1)
    property color gc2: Qt.rgba(0.10,0.08,0.18,1)

    Process {
        id: colorProc; running: false; property int lc: 0
        command: ["bash", "-c",
            "wall=$(swww query 2>/dev/null | grep -o \'image: .*\' | sed \'s/image: //\' | head -1); " +
            "[ -z \"$wall\" ] && echo \'0.06 0.06 0.12\' && echo \'0.10 0.08 0.18\' && exit; " +
            "convert \"$wall\" -resize 50x50! +dither -colors 2 -format \"%[fx:r] %[fx:g] %[fx:b]\n\" info: 2>/dev/null | head -2"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                if (p.length >= 3) {
                    var r=Math.min(parseFloat(p[0])*0.5,0.3)
                    var g=Math.min(parseFloat(p[1])*0.5,0.3)
                    var b=Math.min(parseFloat(p[2])*0.5,0.3)
                    if (colorProc.lc===0) win.gc1=Qt.rgba(r,g,b,1)
                    else                  win.gc2=Qt.rgba(r,g,b,1)
                    colorProc.lc++
                }
            }
        }
        onRunningChanged: if (running) lc=0
    }

    property var staticWalls: []
    property var engineWalls: []
    property var liveWalls:   []
    property int staticIdx: AppState.staticWallIdx
    onStaticIdxChanged: AppState.staticWallIdx = win.staticIdx
    property int engineIdx: 0
    property int liveIdx:   AppState.liveWallIdx

    // Centraliza ao carregar as listas
    onStaticWallsChanged: if (staticWalls.length > 0 && staticIdx === 0) {
        win.staticIdx = Math.floor(staticWalls.length / 2)
        AppState.staticWallIdx = win.staticIdx
    }
    onLiveWallsChanged: if (liveWalls.length > 0 && liveIdx === 0) {
        win.liveIdx = Math.floor(liveWalls.length / 2)
        AppState.liveWallIdx = win.liveIdx
    }

    Process {
        id: findStatic; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => {
            var f=data.trim(); if(f.length>0){var a=win.staticWalls.slice();a.push(f);win.staticWalls=a}
        }}
    }
    Process {
        id: findEngine; running: false
        command: ["bash","-c","for d in ~/.steam/steam/steamapps/workshop/content/431960/*/; do id=$(basename \"$d\"); prev=$(ls \"$d\"preview.* 2>/dev/null | head -1); echo \"$id|$prev\"; done 2>/dev/null"]
        stdout: SplitParser { onRead: data => {
            var l=data.trim(); if(l.length===0)return
            var p=l.split("|"); var a=win.engineWalls.slice()
            a.push({path:p[0],preview:p.length>1?p[1]:""});win.engineWalls=a
        }}
    }
    Process {
        id: findLive; running: false
        command: ["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser { onRead: data => {
            var f=data.trim(); if(f.length>0){var a=win.liveWalls.slice();a.push(f);win.liveWalls=a}
        }}
    }

    Process { id: applyStatic; running: false }
    Process { id: applyEngine; running: false }
    Process { id: applyLive;   running: false }
    Process { id: killEngine; running: false
        command: ["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null; true"] }
    Process { id: killLiveProc; running: false
        command: ["bash","-c","pkill -f mpvpaper 2>/dev/null; true"] }

    Timer { id: engineDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.engineWalls[win.engineIdx]; if (!w) return
            if (w.preview!=="") {
                applyStatic.command=["swww","img",w.preview,"--transition-type","fade","--transition-duration","0.4"]
                applyStatic.running=false; applyStatic.running=true
            }
            applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",w.path]
            applyEngine.running=false; applyEngine.running=true
        }
    }
    Timer { id: liveDebounce; interval: 700; repeat: false
        onTriggered: {
            var w=win.liveWalls[win.liveIdx]; if (!w) return
            applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",w]
            applyLive.running=false; applyLive.running=true
        }
    }

    function applyStaticWall(idx) {
        if (idx<0||idx>=staticWalls.length) return
        AppState.staticWallIdx=idx
        win.staticIdx=idx

        killEngine.running=false; killEngine.running=true
        killLiveProc.running=false; killLiveProc.running=true
        applyStatic.command=["swww","img",staticWalls[idx],"--transition-type","grow","--transition-duration","1","--transition-fps","60"]
        applyStatic.running=false; applyStatic.running=true
    }
    function applyEngineWall(idx) {
        if (idx<0||idx>=engineWalls.length) return
        win.engineIdx=idx
        killLiveProc.running=false; killLiveProc.running=true
        engineDebounce.restart()
    }
    function applyLiveWall(idx) {
        if (idx<0||idx>=liveWalls.length) return
        AppState.liveWallIdx=idx

        win.liveIdx=idx
        liveList.positionViewAtIndex(idx, ListView.Center)
        killEngine.running=false; killEngine.running=true
        liveDebounce.restart()
    }

    Connections {
        target: AppState
        function onOverlayOpenChanged() {
            if (AppState.overlayOpen && AppState.wallpaperOpen) {
                AppState.wallpaperOpen = false
            }
        }
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                closeAnim.stop()
                morph.width=900; morph.height=32
                morph.visible=true; morph.showContent=false
                var w=wb.Window.window; if(w) region.apply(w,0,0,860,260)
                findStatic.running=true; findEngine.running=true; findLive.running=true
                colorProc.running=true
                openAnim.start()
                colorProc.running=true
            } else {
                openAnim.stop(); morph.showContent=false
                closeAnim.start()
            }
        }
    }

    SequentialAnimation {
        id: openAnim
        ScriptAction { script: {
            morph.width=860; morph.height=260
            morph.visible=true; morph.showContent=false
            var w=wb.Window.window; if(w) region.clear(w)
        }}
        PauseAnimation { duration: 130 }
        ScriptAction { script: {
            morph.showContent=true
            keyItem.forceActiveFocus()
            // Posiciona via contentX para respeitar Behavior
        }}
    }

    
    SequentialAnimation {
        id: closeAnim
        ScriptAction { script: {
            morph.showContent=false
        }}
        PauseAnimation { duration: 100 }
        ScriptAction { script: {
            morph.visible=false
            var w=wb.Window.window; if(w) region.apply(w,0,0,860,260)
        }}
    }

    
    Item {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        width: 320; height: 48
        visible: false; clip: true; layer.enabled: true
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 70 ? parent.height/2 : 32
            color: "transparent"; antialiasing: true
            Rectangle {
                anchors.fill: parent; radius: parent.radius; antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,0.30) }
                    GradientStop { position: 1.0; color: Qt.rgba(win.gc2.r,win.gc2.g,win.gc2.b,0.30) }
                }
            }
            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: "transparent"
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
            }
        }

        Item { id: keyItem; anchors.fill: parent; focus: true; Keys.enabled: true
            Keys.onEscapePressed: { AppState.wallpaperOpen=false; AppState.overlayOpen=true }
            Keys.onUpPressed:    AppState.activeWallRow=Math.max(0,AppState.activeWallRow-1)
            Keys.onDownPressed:  AppState.activeWallRow=Math.min(2,AppState.activeWallRow+1)
            Keys.onLeftPressed: {
                if (AppState.activeWallRow===0) win.applyStaticWall(Math.max(0,win.staticIdx-1))
                else if (AppState.activeWallRow===1) win.applyEngineWall(Math.max(0,win.engineIdx-1))
                else win.applyLiveWall(Math.max(0,win.liveIdx-1))
            }
            Keys.onRightPressed: {
                if (AppState.activeWallRow===0) win.applyStaticWall(Math.min(win.staticWalls.length-1,win.staticIdx+1))
                else if (AppState.activeWallRow===1) win.applyEngineWall(Math.min(win.engineWalls.length-1,win.engineIdx+1))
                else win.applyLiveWall(Math.min(win.liveWalls.length-1,win.liveIdx+1))
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 10
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // Labels de categoria
            Row {
                id: labels
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24; height: 20

                Repeater {
                    model: ["Estética", "EnginePaper", "Live"]
                    Text {
                        required property string modelData; required property int index
                        text: modelData
                        color: AppState.activeWallRow===index ? "white" : Qt.rgba(1,1,1,0.28)
                        font.pixelSize: AppState.activeWallRow===index ? 11 : 10
                        font.weight: AppState.activeWallRow===index ? Font.Medium : Font.Normal
                        Behavior on color          { ColorAnimation  { duration: 150 } }
                        Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.activeWallRow=index }
                    }
                }
            }

            // Área dos carrosséis — 3 camadas
            Item {
                id: carouselArea
                anchors.top: labels.bottom; anchors.topMargin: 6
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right

                property real bigH:   height * 0.60
                property real midH:   height * 0.35
                property real smallH: height * 0.20

                // ── Row Estética ──
                // ── Row Estética — carrossel manual ──
                Item {
                    id: staticCarousel
                    width: parent.width
                    height: AppState.activeWallRow===0 ? carouselArea.bigH : carouselArea.smallH
                    anchors.top: parent.top
                    z: AppState.activeWallRow===0 ? 3 : 1
                    clip: true
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                    property real cardW: Math.round(height * 16/9) + 8

                    Repeater {
                        model: win.staticWalls
                        Item {
                            id: sd
                            required property string modelData
                            required property int index
                            property int dist: index - AppState.staticWallIdx
                            property bool active: dist===0 && AppState.activeWallRow===0
                            property bool near: Math.abs(dist)===1
                            property bool shouldLoad: Math.abs(dist)<=3
                            width: staticCarousel.cardW - 8; height: staticCarousel.height
                            x: staticCarousel.width/2 - width/2 + dist * staticCarousel.cardW
                            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            opacity: active ? 1.0 : near ? 0.55 : Math.abs(dist)===2 ? 0.25 : 0.0
                            scale:   active ? 1.0 : near ? 0.88 : 0.78
                            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                            Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            Rectangle {
                                anchors.fill: parent; radius: 14; color: "#0a0a0a"; clip: true
                                Image {
                                    anchors.fill: parent
                                    source: sd.shouldLoad ? "file://"+modelData : ""
                                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                                    opacity: status===Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                                    border.color: sd.active ? Qt.rgba(1,1,1,0.90) : "transparent"
                                    border.width: sd.active ? 2 : 0
                                    Behavior on border.color { ColorAnimation { duration: 220 } }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: win.applyStaticWall(index) }
                        }
                    }
                }

                // ── Row EnginePaper ──
                ListView {
                    id: engineList
                    width: parent.width
                    height: AppState.activeWallRow===1 ? carouselArea.bigH : carouselArea.smallH
                    anchors.verticalCenter: parent.verticalCenter
                    z: AppState.activeWallRow===1 ? 3 : 1
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                    orientation: ListView.Horizontal; spacing: 8; clip: true
                    model: win.engineWalls
                    currentIndex: win.engineIdx
                    property real cardW: Math.round(height * 16/9)
                    
                    delegate: Item {
                        id: ed
                        width: engineList.cardW; height: engineList.height
                        property bool active: index===win.engineIdx && AppState.activeWallRow===1
                        property bool near: Math.abs(index-win.engineIdx)===1
                        property bool shouldLoad: Math.abs(index-win.engineIdx)<=3
                        opacity: active ? 1.0 : near ? 0.55 : 0.25
                        scale:   active ? 1.0 : near ? 0.88 : 0.78
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "#0a0a0a"; clip: true
                            Image {
                                anchors.fill: parent
                                source: (ed.shouldLoad && modelData.preview!=="") ? "file://"+modelData.preview : ""
                                fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                                opacity: status===Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: ed.active ? Qt.rgba(1,1,1,0.75) : "transparent"
                                border.width: 2
                            }
                            Rectangle {
                                anchors.top: parent.top; anchors.topMargin: 4
                                anchors.left: parent.left; anchors.leftMargin: 4
                                width: eb.width+6; height: 12; radius: 3
                                color: Qt.rgba(0,0,0,0.6); visible: ed.active
                                Text { id: eb; anchors.centerIn: parent
                                    text: "ENGINE"; color: "white"
                                    font.pixelSize: 6; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: win.applyEngineWall(index) }
                    }
                }

                // ── Row Live ──
                ListView {
                    id: liveList
                    width: parent.width
                    height: AppState.activeWallRow===2 ? carouselArea.bigH : carouselArea.smallH
                    anchors.bottom: parent.bottom
                    z: AppState.activeWallRow===2 ? 3 : 1
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                    orientation: ListView.Horizontal; spacing: 8; clip: true
                    model: win.liveWalls
                    currentIndex: AppState.liveWallIdx
                    property real cardW: Math.round(height * 16/9)
                    
                    delegate: Item {
                        id: ld
                        width: liveList.cardW; height: liveList.height
                        property bool active: index===win.liveIdx && AppState.activeWallRow===2
                        property bool near: Math.abs(index-win.liveIdx)===1
                        property bool shouldLoad: Math.abs(index-win.liveIdx)<=3
                        property string previewSrc: {
                            if (!shouldLoad) return ""
                            var f=modelData
                            var base=f.replace(/.*\//,"").replace(/\.[^.]+$/,"")
                            return "file:///home/oshiro/.cache/qs_mpv_thumb_"+base+".jpg"
                        }
                        opacity: active ? 1.0 : near ? 0.55 : 0.25
                        scale:   active ? 1.0 : near ? 0.88 : 0.78
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "#0a0a0a"; clip: true
                            Image {
                                id: liveImg
                                anchors.fill: parent; source: ld.previewSrc
                                fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                                cache: false
                                Timer { interval: 1500; running: liveImg.status===Image.Error; repeat: false; onTriggered: { var s=liveImg.source; liveImg.source=""; liveImg.source=s } }
                                opacity: status===Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: ld.active ? Qt.rgba(1,1,1,0.75) : "transparent"
                                border.width: 2
                            }
                            Rectangle {
                                anchors.top: parent.top; anchors.topMargin: 4
                                anchors.left: parent.left; anchors.leftMargin: 4
                                width: lb.width+6; height: 12; radius: 3
                                color: Qt.rgba(0,0,0,0.6); visible: ld.active
                                Text { id: lb; anchors.centerIn: parent
                                    text: "LIVE"; color: "white"
                                    font.pixelSize: 6; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: win.applyLiveWall(index) }
                    }
                }
            }
        }
    }
}
