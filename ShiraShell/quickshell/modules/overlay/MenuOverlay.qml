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
    margins.left: screen ? Math.round((screen.width - 860) / 2) : 510
    color: "transparent"
    implicitWidth: 860
    implicitHeight: 260
    visible: true
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppState.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region { id: emptyMask }
    mask: AppState.menuOpen ? null : emptyMask

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
        stdout: SplitParser { onRead: data => {
            var p=data.trim().split(" ")
            if(p.length>=3){
                var r=Math.min(parseFloat(p[0])*0.9,0.55), g=Math.min(parseFloat(p[1])*0.9,0.55), b=Math.min(parseFloat(p[2])*0.9,0.55)
                if(colorProc.lc===0) win.gc1=Qt.rgba(r,g,b,1); else win.gc2=Qt.rgba(r,g,b,1)
                colorProc.lc++
            }
        }}
        onRunningChanged: if(running) lc=0
    }

    // Estado
    property var gifFiles: []
    property int hovGif: 0
    property bool inConfig: false
    property int configRow: 0  // 0=pixels, 1=velocidade
    property int cols: 3

    Process {
        id: findGifs; running: false
        command: ["bash","-c","ls /home/oshiro/Pictures/gif/*.gif 2>/dev/null"]
        stdout: SplitParser { onRead: data => {
            var f=data.trim(); if(f.length>0){var a=win.gifFiles.slice();a.push(f);win.gifFiles=a}
        }}
    }

    // Navegação
    function keyLeft() {
        if (inConfig) {
            // diminui valor da config atual
            if (configRow===0) AppState.gifSize=Math.max(80,AppState.gifSize-20)
            else AppState.animSpeed=Math.max(0.3,Math.round((AppState.animSpeed-0.1)*10)/10)
        } else {
            if (hovGif > 0) hovGif--
        }
    }
    function keyRight() {
        if (!inConfig) {
            if (hovGif < gifFiles.length-1) hovGif++
            else inConfig=true
        } else {
            // aumenta valor da config atual
            if (configRow===0) AppState.gifSize=Math.min(300,AppState.gifSize+20)
            else AppState.animSpeed=Math.min(3.0,Math.round((AppState.animSpeed+0.1)*10)/10)
        }
    }
    function keyUp() {
        if (!inConfig) { if(hovGif-cols>=0) hovGif-=cols }
        else configRow=Math.max(0,configRow-1)
    }
    function keyDown() {
        if (!inConfig) { if(hovGif+cols<gifFiles.length) hovGif+=cols }
        else configRow=Math.min(1,configRow+1)
    }

    Connections {
        target: AppState
        function onOverlayOpenChanged() {
            if (AppState.overlayOpen && AppState.menuOpen) AppState.menuOpen=false
        }
        function onMenuOpenChanged() {
            if (AppState.menuOpen) {
                closeAnim.stop()
                morph.width=900; morph.height=32
                morph.visible=true; morph.showContent=false
                win.gifFiles=[]; win.hovGif=0; win.inConfig=false
                var w=wb.Window.window; if(w) region.apply(w,0,0,860,260)
                findGifs.running=true; colorProc.running=true
                openAnim.start()
            } else {
                openAnim.stop(); morph.showContent=false
                closeAnim.start()
            }
        }
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "height"; to: 260; duration: 460; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 920; duration: 240; easing.type: Easing.OutCubic }
        NumberAnimation { target: morph; property: "width";  to: 840; duration: 120; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 860; duration: 100; easing.type: Easing.OutCubic }
        ScriptAction { script: { var w=wb.Window.window; if(w) region.clear(w); morph.showContent=true } }
        PauseAnimation { duration: 50 }
        ScriptAction { script: keyItem.forceActiveFocus() }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: morph; property: "height"; to: 32;  duration: 380; easing.type: Easing.InOutCubic }
        NumberAnimation { target: morph; property: "width";  to: 4;   duration: 180; easing.type: Easing.InCubic }
        NumberAnimation { target: morph; property: "width";  to: 260; duration: 160; easing.type: Easing.OutBack }
        ScriptAction { script: { morph.visible=false; var w=wb.Window.window; if(w) region.apply(w,0,0,860,260) } }
    }

    Item {
        id: morph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 900; height: 32
        visible: false; clip: true; layer.enabled: true
        property bool showContent: false

        Rectangle {
            anchors.fill: parent
            radius: parent.height < 70 ? parent.height/2 : 22
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

        Item { id: keyItem; anchors.fill: parent; focus: true
            Keys.onEscapePressed: {
                if (win.inConfig) win.inConfig=false
                else AppState.menuOpen=false
            }
            Keys.onLeftPressed:  win.keyLeft()
            Keys.onRightPressed: win.keyRight()
            Keys.onUpPressed:    win.keyUp()
            Keys.onDownPressed:  win.keyDown()
            Keys.onReturnPressed: if(!win.inConfig) AppState.selectedGif=win.gifFiles[win.hovGif]
        }

        Item {
            anchors.fill: parent; anchors.margins: 10
            opacity: morph.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Row {
                anchors.fill: parent; spacing: 0

                // ── Grid 3x3 de GIFs ──
                Item {
                    width: parent.width * 0.73; height: parent.height

                    Grid {
                        id: gifGrid
                        anchors.centerIn: parent
                        columns: win.cols
                        spacing: 8

                        Repeater {
                            model: win.gifFiles
                            Item {
                                property bool active:   win.hovGif===index && !win.inConfig
                                property bool selected: AppState.selectedGif===modelData
                                property real cellW: (gifGrid.parent.width - 48) / win.cols
                                width: cellW; height: cellW * 0.72
                                scale: active ? 1.06 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: Qt.rgba(0,0,0,0.25); clip: true
                                    AnimatedImage {
                                        anchors.fill: parent; source: "file://"+modelData
                                        fillMode: Image.PreserveAspectCrop
                                        playing: true; smooth: true; asynchronous: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: parent.radius; color: "transparent"
                                        border.width: 2
                                        border.color: parent.parent.active   ? "white"
                                                    : parent.parent.selected ? Qt.rgba(1,0.85,0,0.85)
                                                    : "transparent"
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                    }
                                    Rectangle {
                                        anchors.top: parent.top; anchors.topMargin: 4
                                        anchors.right: parent.right; anchors.rightMargin: 4
                                        width: 16; height: 16; radius: 8
                                        color: Qt.rgba(0.15,0.75,0.25,0.9)
                                        visible: parent.parent.selected
                                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 9 }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: { win.hovGif=index; win.inConfig=false }
                                    onClicked: AppState.selectedGif=win.gifFiles[index]
                                }
                            }
                        }
                    }

                    // Seta → indica configs
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"; font.pixelSize: 22
                        color: win.inConfig ? "white" : Qt.rgba(1,1,1,0.20)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Divisor
                Rectangle {
                    width: 1; height: parent.height * 0.75
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1,1,1,0.08)
                }

                // ── Configurações ──
                Item {
                    width: parent.width * 0.27; height: parent.height

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 16

                        Repeater {
                            model: [
                                {label: "Pixels",     unit: "px",  min: 80,  max: 300, step: 20, row: 0,
                                 value: function(){ return AppState.gifSize },
                                 set:   function(v){ AppState.gifSize=v },
                                 pct:   function(){ return (AppState.gifSize-80)/220 }},
                                {label: "Velocidade", unit: "x",  min: 0.3, max: 3.0, step: 0.1, row: 1,
                                 value: function(){ return AppState.animSpeed },
                                 set:   function(v){ AppState.animSpeed=v },
                                 pct:   function(){ return (AppState.animSpeed-0.3)/2.7 }}
                            ]
                            Item {
                                required property var modelData; required property int index
                                property bool active: win.inConfig && win.configRow===index
                                width: parent.width; height: 52

                                Rectangle {
                                    anchors.fill: parent; radius: 10
                                    color: parent.active ? Qt.rgba(1,1,1,0.10) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    anchors.top: parent.top; anchors.topMargin: 7
                                    anchors.left: parent.left; anchors.leftMargin: 10
                                    text: modelData.label
                                    color: parent.active ? "white" : Qt.rgba(1,1,1,0.40)
                                    font.pixelSize: 10; font.weight: Font.Medium
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    anchors.top: parent.top; anchors.topMargin: 7
                                    anchors.right: parent.right; anchors.rightMargin: 10
                                    text: modelData.row===0
                                        ? AppState.gifSize + "px"
                                        : AppState.animSpeed.toFixed(1) + "x"
                                    color: "white"; font.pixelSize: 11; font.weight: Font.Bold
                                }
                                // Barra de progresso
                                Item {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                                    anchors.left: parent.left; anchors.leftMargin: 10
                                    anchors.right: parent.right; anchors.rightMargin: 10
                                    height: 3
                                    Rectangle {
                                        anchors.fill: parent; radius: 2
                                        color: Qt.rgba(1,1,1,0.10)
                                    }
                                    Rectangle {
                                        height: parent.height; radius: 2
                                        color: Qt.rgba(1,1,1,0.70)
                                        width: parent.width * (modelData.row===0
                                            ? (AppState.gifSize-80)/220
                                            : (AppState.animSpeed-0.3)/2.7)
                                        Behavior on width { NumberAnimation { duration: 120 } }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: { win.inConfig=true; win.configRow=index }
                                    onWheel: event => {
                                        var d = event.angleDelta.y > 0 ? modelData.step : -modelData.step
                                        if (modelData.row===0) AppState.gifSize=Math.min(300,Math.max(80,AppState.gifSize+Math.round(d)))
                                        else AppState.animSpeed=Math.min(3.0,Math.max(0.3,Math.round((AppState.animSpeed+d)*10)/10))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
