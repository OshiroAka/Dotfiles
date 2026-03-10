import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import ShiraOS
import "../../services"

PanelWindow {
    id: win

    WlrLayershell.namespace:     "shiraos-island-expanded"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: AppState.islandOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    margins.top:   6

    implicitWidth:  screen ? screen.width : 1920
    implicitHeight: 340
    color:     Qt.rgba(0, 0, 0, 0.01)
    focusable: true

    visible: AppState.islandOpen || openAnim.running || closeAnim.running

    Region { id: emptyMask }
    mask: AppState.islandOpen ? null : emptyMask

    MprisService { id: mpris }
    property var cavaValues: [0,0,0,0,0,0,0,0,0,0,0,0]
    Process {
        command: ["/bin/bash", "-c", "/home/oshiro/.local/bin/shiraos-cava"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.trim().split(",")
                if (p.length === 12) {
                    var v = []; for (var i=0;i<12;i++) v.push(parseInt(p[i])/255.0)
                    win.cavaValues = v
                }
            }
        }
    }

    // ── Helpers de cor ────────────────────────────────────────────────────
    function pillColor()   { return AppState.accentPill   ? AppState.accentPill   : Qt.rgba(0.06,0.06,0.09,0.12) }
    function darkCol()     { return AppState.accentDark   ? AppState.accentDark   : Qt.rgba(0.10,0.08,0.18,0.90) }
    function borderColor() { return AppState.accentBorder ? AppState.accentBorder : Qt.rgba(0.3,0.3,0.6,0.25) }
    function accentCol()   { return AppState.accentColor  ? AppState.accentColor  : Qt.rgba(0.55,0.55,1.0,1.0) }
    function textCol(bright) {
        // bright=true → cor accent saturada, false → branco com leve tint
        if (!AppState.accentColor) return "white"
        var c = AppState.accentColor
        return bright
            ? Qt.rgba(c.r*0.7+0.3, c.g*0.7+0.3, c.b*0.7+0.3, 1.0)
            : Qt.rgba(c.r*0.3+0.7, c.g*0.3+0.7, c.b*0.3+0.7, 1.0)
    }

    // ── Estados ───────────────────────────────────────────────────────────
    // mode: 0=1/2 expandida  1=2/2 dual pill  2=overview
    property int  mode:    0
    property bool busy:    false
    property int  frontCat:   0
    property int  backCat:    0
    property int  overviewSel: 0   // categoria selecionada no overview (0-2 das menores)

    function catExpandH(c) { return c === 1 ? 240 : 96 }
    function catExpandW(c) { return c === 1 ? 440 : 360 }
    function catName(c)    { return ["Relógio","Música","CPU","Clima"][c] }
    function catIcon(c)    { return ["🕐","♫","⚡","☁"][c] }

    // ── Pill expandida (modo 0) ───────────────────────────────────────────
    property real pillW:  260
    property real pillH:  36
    property real pillOp: 0.0

    // ── Dual pill (modo 1) ────────────────────────────────────────────────
    property real frontScale:  1.0
    property real frontY:      0.0
    property real frontOpDual: 1.0
    property real backScale:   0.82
    property real backOpacity: 0.0

    // ── Overview (modo 2) ─────────────────────────────────────────────────
    property real overviewOp: 0.0
    property real overviewH:  270

    // ── Abrir ─────────────────────────────────────────────────────────────
    SequentialAnimation {
        id: openAnim
        PauseAnimation { duration: 80 }
        NumberAnimation { target: win; property: "pillOp"; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; id: openW; property: "pillW";  to: 360; duration: 180; easing.type: Easing.OutExpo }
        NumberAnimation { id: openH; target: win; property: "pillH"; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        ScriptAction { script: keyItem.forceActiveFocus() }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: win; property: "backOpacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: win; property: "overviewOp";  to: 0.0; duration: 120 }
        NumberAnimation { target: win; property: "pillH";  to: 36;  duration: 200; easing.type: Easing.InBack;  easing.overshoot: 0.8 }
        NumberAnimation { target: win; property: "pillW";  to: 260; duration: 160; easing.type: Easing.InExpo }
        NumberAnimation { target: win; property: "pillOp"; to: 0.0; duration: 80;  easing.type: Easing.InCubic }
        ScriptAction { script: { win.mode = 0; AppState.islandOpen = false } }
    }

    Connections {
        target: AppState
        function onIslandOpenChanged() {
            if (AppState.islandOpen) {
                win.pillW = 260; win.pillH = 36; win.pillOp = 0.0
                win.backOpacity = 0.0; win.overviewOp = 0.0
                win.mode = 0; win.frontY = 0; win.frontScale = 1.0; win.frontOpDual = 1.0
                openH.to = win.catExpandH(win.frontCat)
                openW.to = win.catExpandW(win.frontCat)
                openAnim.start()
            } else {
                if (!closeAnim.running) closeAnim.start()
            }
        }
    }

    // ── Entrar em modo 2/2 ────────────────────────────────────────────────
    SequentialAnimation {
        id: enterDual
        ScriptAction {
            script: {
                win.busy = true
                win.backCat  = win.frontCat
                win.frontCat = (win.frontCat + 1) % 4
                win.frontY = 0; win.frontScale = 1.0; win.frontOpDual = 1.0
            }
        }
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: win; property: "pillH"; to: 36;  duration: 180; easing.type: Easing.InBack; easing.overshoot: 0.8 }
                NumberAnimation { target: win; property: "pillW"; to: 260; duration: 150; easing.type: Easing.InExpo }
            }
            SequentialAnimation {
                PauseAnimation  { duration: 50 }
                NumberAnimation { target: win; property: "backOpacity"; to: 0.85; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: { win.mode = 1; win.busy = false; keyItem.forceActiveFocus() } }
    }

    // ── Swap roda (↑ em modo 1) ───────────────────────────────────────────
    SequentialAnimation {
        id: swapDual
        ScriptAction { script: win.busy = true }
        ParallelAnimation {
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: win; property: "frontY";      to:  70; duration: 200; easing.type: Easing.InExpo }
                    NumberAnimation { target: win; property: "frontScale";  to: 0.4; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: win; property: "frontOpDual"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                }
                ScriptAction {
                    script: {
                        var tmp = win.frontCat; win.frontCat = win.backCat; win.backCat = tmp
                        win.frontY = -60; win.frontScale = 0.4; win.frontOpDual = 0.0
                    }
                }
                ParallelAnimation {
                    NumberAnimation { target: win; property: "frontY";      from: -60; to:  0;  duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    NumberAnimation { target: win; property: "frontScale";  from:  0.4; to: 1.0; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
                    NumberAnimation { target: win; property: "frontOpDual"; from:  0.0; to: 1.0; duration: 240; easing.type: Easing.OutCubic }
                }
            }
            SequentialAnimation {
                PauseAnimation  { duration: 100 }
                NumberAnimation { target: win; property: "backScale"; to: 0.68; duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { target: win; property: "backScale"; to: 0.82; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
            }
        }
        ScriptAction { script: { win.busy = false; keyItem.forceActiveFocus() } }
    }

    // ── Sair do modo 2/2 ─────────────────────────────────────────────────
    SequentialAnimation {
        id: exitDual
        ScriptAction { script: win.busy = true }
        ParallelAnimation {
            NumberAnimation { target: win; property: "backOpacity"; to: 0.0; duration: 180; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: win; property: "pillW"; to: 360; duration: 160; easing.type: Easing.OutExpo }
                NumberAnimation { id: exitH; target: win; property: "pillH"; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
        }
        ScriptAction {
            script: {
                win.mode = 0; win.frontScale = 1.0; win.backScale = 0.82
                win.frontY = 0; win.frontOpDual = 1.0; win.busy = false
                keyItem.forceActiveFocus()
            }
        }
    }

    // ── Entrar em overview (Enter) ────────────────────────────────────────
    SequentialAnimation {
        id: enterOverview
        ScriptAction { script: { win.busy = true; win.overviewSel = 0 } }
        ParallelAnimation {
            // back some
            NumberAnimation { target: win; property: "backOpacity"; to: 0.0; duration: 150 }
            // pill expande para altura do overview
            NumberAnimation { target: win; property: "pillW"; to: 380; duration: 200; easing.type: Easing.OutExpo }
            NumberAnimation { target: win; property: "pillH"; to: win.overviewH; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
        }
        NumberAnimation { target: win; property: "overviewOp"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        ScriptAction { script: { win.mode = 2; win.busy = false; keyItem.forceActiveFocus() } }
    }

    // ── Sair do overview (Enter na selecionada) ───────────────────────────
    SequentialAnimation {
        id: exitOverview
        ScriptAction { script: win.busy = true }
        NumberAnimation { target: win; property: "overviewOp"; to: 0.0; duration: 140; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: win; property: "pillW"; to: 360; duration: 180; easing.type: Easing.InExpo }
            NumberAnimation { id: exitOvH; target: win; property: "pillH"; duration: 220; easing.type: Easing.InBack; easing.overshoot: 0.8 }
        }
        // Shooter para nova categoria
        NumberAnimation { target: win; property: "pillW"; to: 360; duration: 180; easing.type: Easing.OutExpo }
        NumberAnimation { id: exitOvExpand; target: win; property: "pillH"; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        ScriptAction { script: { win.mode = 0; win.busy = false; keyItem.forceActiveFocus() } }
    }

    // ── Outros indices do overview (as 3 categorias menores) ─────────────
    function overviewOtherCat(slot) {
        // slot 0,1,2 → as 3 categorias que não são frontCat
        var others = []
        for (var i = 0; i < 4; i++) if (i !== win.frontCat) others.push(i)
        return others[slot]
    }

    function pressEnter() {
        if (busy || openAnim.running || closeAnim.running) return
        if (mode === 0 || mode === 1) {
            // Fecha dual se necessário e entra no overview
            if (mode === 1) { backOpacity = 0.0; mode = 0 }
            enterOverview.start()
        } else if (mode === 2) {
            // Seleciona categoria do overview
            var chosen = overviewSel < 0 ? frontCat : overviewOtherCat(overviewSel)
            frontCat   = chosen
            exitOvH.to      = 36
            exitOvExpand.to = catExpandH(chosen)
            exitOverview.start()
        }
    }

    function pressUp() {
        if (busy || openAnim.running || closeAnim.running || mode === 2) return
        if (mode === 0) enterDual.start()
        else if (mode === 1 && !swapDual.running) swapDual.start()
    }

    function pressDown() {
        if (busy || openAnim.running) return
        if (mode === 2) {
            // Cancela overview, volta para 1/2
            exitOvH.to      = catExpandH(frontCat)
            exitOvExpand.to = catExpandH(frontCat)
            exitOverview.start()
        } else if (mode === 1) {
            exitH.to = catExpandH(frontCat)
            exitDual.start()
        } else if (!closeAnim.running) {
            closeAnim.start()
        }
    }

    // ── Render ────────────────────────────────────────────────────────────
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:  parent.top; anchors.topMargin: 4
        width: 420; height: 320

        // ── Back pill (modo 1) ────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 10
            width: 260; height: 36
            scale:   win.backScale
            opacity: win.backOpacity
            transformOrigin: Item.Top
            z: 0
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled:true; blur:0.4; blurMax:16; blurMultiplier:0.9 }
            Rectangle { anchors.fill:parent; radius:height/2; color:win.pillColor(); border.color:win.borderColor(); border.width:1 }
            CompactContent { anchors.fill:parent; anchors.margins:6; catIndex:win.backCat }
        }

        // ── Front / overview pill (z:1) ───────────────────────────────────
        Item {
            id: frontPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:  parent.top
            anchors.topMargin: win.mode===1 ? win.frontY : 0
            width:  win.mode===1 ? 260 : win.pillW
            height: win.mode===1 ? 36  : win.pillH
            scale:  win.mode===1 ? win.frontScale : 1.0
            opacity: win.mode===1 ? (win.pillOp*win.frontOpDual) : win.pillOp
            transformOrigin: Item.Top
            z: 1

            Behavior on width  { enabled: win.mode===0 && !openAnim.running && !closeAnim.running && !exitDual.running; NumberAnimation { duration:400; easing.type:Easing.OutExpo } }
            Behavior on height { enabled: win.mode===0 && !openAnim.running && !closeAnim.running && !exitDual.running; NumberAnimation { duration:400; easing.type:Easing.OutExpo } }

            Rectangle {
                anchors.fill: parent
                radius: win.mode===1 ? height/2 : 18
                color:  win.pillColor()
                border.color: win.borderColor(); border.width: 1
                Behavior on radius { NumberAnimation { duration:200 } }
                Rectangle {
                    anchors.fill:parent; anchors.margins:-4; radius:parent.radius+4; color:"transparent"
                    border.color:Qt.rgba(0,0,0,0.35); border.width:4; z:-1
                    opacity: win.pillOp>=0.1 && win.mode===0 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration:60 } }
                }
            }

            // Key handler
            Item {
                id: keyItem; anchors.fill:parent; focus:true
                Keys.onUpPressed:     { win.pressUp() }
                Keys.onDownPressed:   { win.pressDown() }
                Keys.onEscapePressed: { win.pressDown() }
                Keys.onReturnPressed: { win.pressEnter() }
                Keys.onEnterPressed:  { win.pressEnter() }
                Keys.onLeftPressed: {
                    if (win.mode===2) {
                        win.overviewSel = (win.overviewSel + 2) % 3
                    } else if (win.mode===0 && !win.busy && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat+3)%4
                        win.pillH    = win.catExpandH(win.frontCat)
                        win.pillW    = win.catExpandW(win.frontCat)
                    }
                }
                Keys.onRightPressed: {
                    if (win.mode===2) {
                        win.overviewSel = (win.overviewSel + 1) % 3
                    } else if (win.mode===0 && !win.busy && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat+1)%4
                        win.pillH    = win.catExpandH(win.frontCat)
                        win.pillW    = win.catExpandW(win.frontCat)
                    }
                }
            }

            // ── Conteúdo modo 0 (expandido) ───────────────────────────────
            Item {
                visible: win.mode === 0
                anchors.fill: parent
                opacity: frontPill.height > 70 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration:100 } }
                Row {
                    id: dotsRow; anchors.top:parent.top; anchors.topMargin:10
                    anchors.horizontalCenter:parent.horizontalCenter; spacing:6
                    Repeater { model:4; delegate: Rectangle {
                        width:win.frontCat===index?16:5; height:5; radius:2.5
                        color:win.frontCat===index?win.accentCol():Qt.rgba(1,1,1,0.25)
                        Behavior on width { NumberAnimation { duration:180; easing.type:Easing.OutExpo } }
                        Behavior on color { ColorAnimation  { duration:150 } }
                    }}
                }
                Item {
                    anchors.top:dotsRow.bottom; anchors.topMargin:8
                    anchors.left:parent.left; anchors.right:parent.right
                    anchors.bottom:parent.bottom; anchors.bottomMargin:8; clip:true
                    ExpandedContent { catIndex: win.frontCat }
                }
            }

            // ── Conteúdo modo 1 (compacto dual) ───────────────────────────
            CompactContent {
                visible: win.mode === 1
                anchors.fill:parent; anchors.margins:6; catIndex:win.frontCat
            }

            // ── Overview (modo 2) — dashboard completo ────────────────
            Item {
                visible: win.mode === 2
                anchors.fill: parent
                opacity: win.overviewOp
                Behavior on opacity { NumberAnimation { duration:150 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // ── Linha 1: Relógio + Música ─────────────────────────
                    Row {
                        width: parent.width; height: 100; spacing: 10

                        // Relógio
                        Rectangle {
                            width: (parent.width - 10) * 0.38; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.55)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=0; win.pressEnter() } }
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: win.textCol(false); font.pixelSize: 28; font.bold: true
                                    Timer { interval:1000; running:true; repeat:true; triggeredOnStart:true
                                            onTriggered: parent.text = Qt.formatTime(new Date(),"HH:mm") }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatDate(new Date(),"ddd, dd MMM")
                                    color: Qt.rgba(win.accentCol().r*0.5+0.5, win.accentCol().g*0.5+0.5, win.accentCol().b*0.5+0.5, 0.65)
                                    font.pixelSize: 9
                                }
                            }
                        }

                        // Música
                        Rectangle {
                            width: (parent.width - 10) * 0.62; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.55)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=1; win.pressEnter() } }

                            // Sem player
                            Column { visible:!mpris.hasPlayer; anchors.centerIn:parent; spacing:4
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"♫";color:win.accentCol();font.pixelSize:22}
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"Nenhuma mídia";color:Qt.rgba(1,1,1,0.3);font.pixelSize:9}
                            }

                            // Com player
                            Row { visible:mpris.hasPlayer; anchors.fill:parent; anchors.margins:10; spacing:8
                                Rectangle { width:50;height:50;radius:8;color:Qt.rgba(1,1,1,0.06);clip:true;anchors.verticalCenter:parent.verticalCenter
                                    Image{anchors.fill:parent;source:mpris.albumArt;fillMode:Image.PreserveAspectCrop;visible:mpris.albumArt!==""}
                                    Text{anchors.centerIn:parent;visible:mpris.albumArt==="";text:"♫";color:win.accentCol();font.pixelSize:20}
                                }
                                Column { anchors.verticalCenter:parent.verticalCenter; width:parent.width-58; spacing:4
                                    Text{width:parent.width;text:mpris.title||"";color:win.textCol(false);font.pixelSize:11;font.bold:true;elide:Text.ElideRight}
                                    Text{width:parent.width;text:mpris.artist||"";color:win.accentCol();font.pixelSize:9;elide:Text.ElideRight}
                                    Item{width:parent.width;height:2
                                        Rectangle{anchors.fill:parent;radius:1;color:win.borderColor()}
                                        Rectangle{width:parent.width*mpris.progress;height:parent.height;radius:1;color:win.accentCol()
                                            Behavior on width{NumberAnimation{duration:1000;easing.type:Easing.Linear}}}
                                    }
                                    Row{spacing:14
                                        Text{text:"⏮";color:win.accentCol();font.pixelSize:11;MouseArea{anchors.fill:parent;onClicked:mpris.prev()}}
                                        Text{text:mpris.playing?"⏸":"▶";color:win.textCol(false);font.pixelSize:13;MouseArea{anchors.fill:parent;onClicked:mpris.playPause()}}
                                        Text{text:"⏭";color:win.accentCol();font.pixelSize:11;MouseArea{anchors.fill:parent;onClicked:mpris.next()}}
                                    }
                                }
                            }
                        }
                    }

                    // ── Linha 2: CPU/RAM + Clima ──────────────────────────
                    Row {
                        width: parent.width; height: 70; spacing: 10

                        // CPU/RAM
                        Rectangle {
                            width: (parent.width - 10) * 0.5; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.30)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=2; win.pressEnter() } }
                            Column { anchors.centerIn:parent; spacing:4
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"CPU / RAM";color:win.accentCol();font.pixelSize:8}
                                Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:12
                                    Text{text:"–%";color:win.textCol(false);font.pixelSize:18;font.bold:true}
                                    Text{text:"–%";color:Qt.rgba(win.accentCol().r*0.7+0.3,win.accentCol().g*0.7+0.3,win.accentCol().b*0.7+0.3,0.8);font.pixelSize:18;font.bold:true}
                                }
                            }
                        }

                        // Clima
                        Rectangle {
                            width: (parent.width - 10) * 0.5; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.55)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=3; win.pressEnter() } }
                            Row { anchors.centerIn:parent; spacing:8
                                Text{anchors.verticalCenter:parent.verticalCenter;text:"☁";font.pixelSize:24;color:win.accentCol()}
                                Column{anchors.verticalCenter:parent.verticalCenter;spacing:2
                                    Text{text:"–°";color:win.textCol(false);font.pixelSize:20;font.bold:true}
                                    Text{text:"em breve";color:win.accentCol();font.pixelSize:8}
                                }
                            }
                        }
                    }

                    // ── Visualizer + dica ─────────────────────────────────
                    Row {
                        width: parent.width; height: 28; spacing: 4
                        Repeater { model:12; delegate: Item {
                            width:(parent.width-44)/12; height:parent.height
                            property real barH:Math.max(3,(win.cavaValues[index]||0)*height)
                            Behavior on barH{NumberAnimation{duration:80;easing.type:Easing.OutCubic}}
                            Rectangle { width: 4; height: parent.barH; radius: 2; x: (parent.width - 4) / 2; y: parent.height - parent.barH
                                color:Qt.rgba(win.accentCol().r*0.5+0.5,win.accentCol().g*0.5+0.5,win.accentCol().b*0.5+0.5,0.5+(parent.barH/28.0)*0.5)}
                        }}
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill:parent; z:-1
        onClicked: { if (!closeAnim.running) win.pressDown() }
    }

    // ── Pill compacta ─────────────────────────────────────────────────────
    component CompactContent: Item {
        property int catIndex: 0
        Text { visible:catIndex===0; anchors.centerIn:parent; color:win.textCol(false); font.pixelSize:13; font.weight:Font.Medium
               Timer{interval:1000;running:true;repeat:true;triggeredOnStart:true;onTriggered:parent.text=Qt.formatTime(new Date(),"HH:mm")} }
        Row  { visible:catIndex===1&&mpris.hasPlayer; anchors.centerIn:parent; spacing:5
               Text{text:"♫";color:win.accentCol();font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
               Text{text:mpris.title||"";color:win.textCol(false);font.pixelSize:10;width:100;elide:Text.ElideRight;anchors.verticalCenter:parent.verticalCenter} }
        Text { visible:catIndex===1&&!mpris.hasPlayer; anchors.centerIn:parent; text:"♫"; color:win.accentCol(); font.pixelSize:14 }
        Row  { visible:catIndex===2; anchors.centerIn:parent; spacing:5
               Text{text:"CPU";color:win.accentCol();font.pixelSize:9;anchors.verticalCenter:parent.verticalCenter}
               Text{text:"–%";color:win.textCol(false);font.pixelSize:13;font.bold:true;anchors.verticalCenter:parent.verticalCenter} }
        Row  { visible:catIndex===3; anchors.centerIn:parent; spacing:5
               Text{text:"☁";color:win.accentCol();font.pixelSize:13;anchors.verticalCenter:parent.verticalCenter}
               Text{text:"–°";color:win.textCol(false);font.pixelSize:13;font.bold:true;anchors.verticalCenter:parent.verticalCenter} }
    }

    // ── Conteúdo expandido ────────────────────────────────────────────────
    component ExpandedContent: Item {
        id: ec; anchors.fill:parent; property int catIndex:0

        Column{visible:ec.catIndex===0;anchors.centerIn:parent;spacing:2
            Text{anchors.horizontalCenter:parent.horizontalCenter;color:win.textCol(false);font.pixelSize:26;font.bold:true
                 Timer{interval:1000;running:true;repeat:true;triggeredOnStart:true;onTriggered:parent.text=Qt.formatTime(new Date(),"HH:mm")}}
            Text{anchors.horizontalCenter:parent.horizontalCenter;text:Qt.formatDate(new Date(),"ddd, dd MMM");color:Qt.rgba(win.accentCol().r*0.5+0.5,win.accentCol().g*0.5+0.5,win.accentCol().b*0.5+0.5,0.60);font.pixelSize:10}
        }

        // ── Categoria 1: Música — estilo vinil ───────────────────────────────
        Item {
            visible: ec.catIndex === 1
            anchors.fill: parent
            clip: true

            // Sem player
            Column {
                visible: !mpris.hasPlayer
                anchors.centerIn: parent; spacing: 6
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"♫"; color:win.accentCol(); font.pixelSize:28 }
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"Nenhuma mídia"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:11 }
            }

            // Com player
            Item {
                visible: mpris.hasPlayer
                anchors.fill: parent

                // ── Disco (esquerda, centralizado verticalmente) ──────────
                Item {
                    id: discItem
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    width: Math.min(parent.height - 8, parent.width * 0.52)
                    height: width

                    // Rotação do disco inteiro
                    NumberAnimation on rotation {
                        from: 0; to: 360
                        duration: 5000
                        loops: Animation.Infinite
                        running: mpris.playing
                        easing.type: Easing.Linear
                    }

                    // Fundo do disco (preto vinil)
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#111111"
                    }

                    // Ranhuras do vinil — anéis concêntricos
                    Repeater {
                        model: 8
                        Rectangle {
                            anchors.centerIn: parent
                            property real s: (0.92 - index * 0.06)
                            width: discItem.width * s; height: width
                            radius: width / 2
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.04 + index * 0.01)
                            border.width: 1
                        }
                    }

                    // Album art circular (centro)
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.50; height: width
                        radius: width / 2
                        clip: true
                        color: Qt.rgba(0.1, 0.1, 0.1, 1)

                        Image {
                            anchors.fill: parent
                            source: mpris.albumArt || ""
                            fillMode: Image.PreserveAspectCrop
                            visible: mpris.albumArt !== ""
                            smooth: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: mpris.albumArt === ""
                            text: "♫"; color: win.accentCol(); font.pixelSize: 22
                        }
                    }

                    // Furo central
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10; height: 10; radius: 5
                        color: "#222222"
                        border.color: win.accentCol(); border.width: 1
                    }

                    // Visualizer circular — pontos em volta do disco
                    Repeater {
                        model: 12
                        Item {
                            anchors.centerIn: parent
                            width: discItem.width; height: discItem.height
                            rotation: index * 30
                            property real barH: Math.max(2, (win.cavaValues[index] || 0) * discItem.width * 0.14)
                            Behavior on barH { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            Rectangle {
                                x: parent.width / 2 - width / 2
                                y: 1
                                width: 3; height: parent.barH
                                radius: 2
                                color: Qt.rgba(
                                    win.accentCol().r * 0.5 + 0.5,
                                    win.accentCol().g * 0.5 + 0.5,
                                    win.accentCol().b * 0.5 + 0.5,
                                    0.5 + (parent.barH / (discItem.width * 0.14)) * 0.5
                                )
                            }
                        }
                    }
                }

                // ── Info (direita) ────────────────────────────────────────
                Column {
                    anchors.left: discItem.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        width: parent.width
                        text: mpris.title || "Sem título"
                        color: win.textCol(false)
                        font.pixelSize: 13; font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: mpris.artist || ""
                        color: win.accentCol()
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    // Barra de progresso
                    Item { width: parent.width; height: 3
                        Rectangle { anchors.fill:parent; radius:2; color:win.borderColor() }
                        Rectangle {
                            width: parent.width * mpris.progress
                            height: parent.height; radius: 2
                            color: win.accentCol()
                            Behavior on width { NumberAnimation { duration:1000; easing.type:Easing.Linear } }
                        }
                    }

                    // Controles
                    Row {
                        spacing: 16
                        Text { text:"⏮"; color:win.accentCol(); font.pixelSize:14; MouseArea{anchors.fill:parent;onClicked:mpris.prev()} }
                        Text { text:mpris.playing?"⏸":"▶"; color:win.textCol(false); font.pixelSize:18; MouseArea{anchors.fill:parent;onClicked:mpris.playPause()} }
                        Text { text:"⏭"; color:win.accentCol(); font.pixelSize:14; MouseArea{anchors.fill:parent;onClicked:mpris.next()} }
                    }
                }
            }
        }

        Column{visible:ec.catIndex===2;anchors.centerIn:parent;spacing:4
            Text{anchors.horizontalCenter:parent.horizontalCenter;text:"CPU  —  RAM";color:win.accentCol();font.pixelSize:9}
            Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:16
                Text{text:"–%";color:win.textCol(false);font.pixelSize:24;font.bold:true}
                Text{text:"–%";color:Qt.rgba(win.accentCol().r*0.7+0.3,win.accentCol().g*0.7+0.3,win.accentCol().b*0.7+0.3,0.8);font.pixelSize:24;font.bold:true}
            }
        }

        Row{visible:ec.catIndex===3;anchors.centerIn:parent;spacing:10
            Text{anchors.verticalCenter:parent.verticalCenter;text:"☁";font.pixelSize:30;color:win.accentCol()}
            Column{anchors.verticalCenter:parent.verticalCenter;spacing:2
                Text{text:"–°";color:win.textCol(false);font.pixelSize:24;font.bold:true}
                Text{text:"em breve";color:win.accentCol();font.pixelSize:9}
            }
        }
    }
}
