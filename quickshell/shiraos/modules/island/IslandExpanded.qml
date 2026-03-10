import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
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
    implicitHeight: 240
    color:     Qt.rgba(0, 0, 0, 0.01)
    focusable: true

    visible: AppState.islandOpen || openAnim.running || closeAnim.running

    Region { id: emptyMask }
    mask: AppState.islandOpen ? null : emptyMask

    // ── MPRIS + Cava ──────────────────────────────────────────────────────
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

    // ── Estado ────────────────────────────────────────────────────────────
    // Modo 1/2: só frontPill visível, expandida
    // Modo 2/2: duas pills compactas, front maior, back menor atrás
    property bool dualMode: false
    property bool busy:     false

    // Categorias
    property int frontCat: 0   // categoria da pill da frente
    property int backCat:  0   // categoria da pill de trás

    // Dimensões da pill expandida (modo 1/2)
    property real expandW: 360
    property real expandH: 96   // atualizado por setExpandH()

    function catExpandH(c) { return c === 1 ? 180 : 96 }

    // ── Animações pill expandida (modo 1/2) ───────────────────────────────
    property real pillW:  260
    property real pillH:  36
    property real pillOp: 0.0

    SequentialAnimation {
        id: openAnim
        PauseAnimation { duration: 80 }
        NumberAnimation { target: win; property: "pillOp"; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "pillW";  to: 360; duration: 180; easing.type: Easing.OutExpo }
        NumberAnimation { id: openH; target: win; property: "pillH"; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        ScriptAction { script: keyItem.forceActiveFocus() }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: win; property: "backOpacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: win; property: "pillH";  to: 36;  duration: 200; easing.type: Easing.InBack;  easing.overshoot: 0.8 }
        NumberAnimation { target: win; property: "pillW";  to: 260; duration: 160; easing.type: Easing.InExpo }
        NumberAnimation { target: win; property: "pillOp"; to: 0.0; duration: 80;  easing.type: Easing.InCubic }
        ScriptAction { script: { win.dualMode = false; AppState.islandOpen = false } }
    }

    Connections {
        target: AppState
        function onIslandOpenChanged() {
            if (AppState.islandOpen) {
                win.pillW = 260; win.pillH = 36; win.pillOp = 0.0
                win.backOpacity = 0.0; win.dualMode = false
                openH.to = win.catExpandH(win.frontCat)
                openAnim.start()
            } else {
                if (!closeAnim.running) closeAnim.start()
            }
        }
    }

    // ── Estado dual pill ──────────────────────────────────────────────────
    // Tamanhos compactos (pill pequena)
    property real compactW: 260
    property real compactH: 36

    // Front pill (modo 2/2) — tamanho da pill da frente
    property real frontScale: 1.0
    property real backScale:  0.78
    property real backOpacity: 0.0

    // ── Entrar em modo 2/2 ────────────────────────────────────────────────
    SequentialAnimation {
        id: enterDual
        ScriptAction {
            script: {
                win.busy    = true
                win.backCat = win.frontCat
                win.frontCat = (win.frontCat + 1) % 4
            }
        }
        ParallelAnimation {
            // Pill atual (front) colapsa para compacta
            SequentialAnimation {
                NumberAnimation { target: win; property: "pillH"; to: 36;  duration: 180; easing.type: Easing.InBack; easing.overshoot: 0.8 }
                NumberAnimation { target: win; property: "pillW"; to: 260; duration: 160; easing.type: Easing.InExpo }
            }
            // Back aparece pequena atrás
            SequentialAnimation {
                PauseAnimation  { duration: 60 }
                NumberAnimation { target: win; property: "backOpacity"; to: 0.85; duration: 120; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction {
            script: {
                win.dualMode = true
                win.busy     = false
                keyItem.forceActiveFocus()
            }
        }
    }

    // ── Trocar pills (↑ em modo 2/2) ─────────────────────────────────────
    // Back vem para frente (escala sobe), front vai para trás (escala desce)
    SequentialAnimation {
        id: swapDual
        ScriptAction { script: win.busy = true }
        ParallelAnimation {
            // Front vai para trás: encolhe
            SequentialAnimation {
                NumberAnimation { target: win; property: "frontScale"; to: win.backScale; duration: 220; easing.type: Easing.InOutCubic }
                ScriptAction {
                    script: {
                        // Troca categorias
                        var tmp = win.frontCat
                        win.frontCat = win.backCat
                        win.backCat  = tmp
                        win.frontScale = win.backScale
                    }
                }
                NumberAnimation { target: win; property: "frontScale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
            }
            // Back pulsa levemente
            SequentialAnimation {
                NumberAnimation { target: win; property: "backScale"; to: 0.70; duration: 180; easing.type: Easing.InCubic }
                NumberAnimation { target: win; property: "backScale"; to: 0.78; duration: 160; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
            }
        }
        ScriptAction { script: { win.busy = false; keyItem.forceActiveFocus() } }
    }

    // ── Sair do modo 2/2 (↓) ─────────────────────────────────────────────
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
                win.dualMode = false
                win.frontScale = 1.0
                win.backScale  = 0.78
                win.busy       = false
                keyItem.forceActiveFocus()
            }
        }
    }

    function pressUp() {
        if (busy || openAnim.running || closeAnim.running) return
        if (!dualMode) {
            enterDual.start()
        } else {
            if (!swapDual.running) swapDual.start()
        }
    }

    function pressDown() {
        if (busy || openAnim.running) return
        if (dualMode) {
            exitH.to = catExpandH(frontCat)
            exitDual.start()
        } else if (!closeAnim.running) {
            closeAnim.start()
        }
    }

    // ── Render ────────────────────────────────────────────────────────────
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.top
        anchors.topMargin:        4
        width: 400; height: 220

        // ── Back pill (z:0) — compacta, atrás ────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:  parent.top
            width:        win.compactW * win.backScale
            height:       win.compactH * win.backScale
            opacity:      win.backOpacity
            scale:        1.0
            z: 0

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color:  AppState.accentPill ? AppState.accentPill : Qt.rgba(0.06, 0.06, 0.09, 0.60)
                border.color: AppState.accentBorder ? AppState.accentBorder : Qt.rgba(0.3, 0.3, 0.6, 0.25); border.width: 1
            }

            // Conteúdo compacto
            CompactContent {
                anchors.fill: parent
                anchors.margins: 6
                catIndex: win.backCat
            }
        }

        // ── Front pill (z:1) ──────────────────────────────────────────────
        Item {
            id: frontPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:  parent.top
            width:  win.dualMode ? win.compactW : win.pillW
            height: win.dualMode ? win.compactH : win.pillH
            opacity: win.pillOp
            scale:  win.dualMode ? win.frontScale : 1.0
            transformOrigin: Item.Center
            z: 1

            Behavior on width  { enabled: !win.dualMode && !openAnim.running && !closeAnim.running && !exitDual.running; NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on height { enabled: !win.dualMode && !openAnim.running && !closeAnim.running && !exitDual.running; NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

            Rectangle {
                anchors.fill: parent
                radius: win.dualMode ? height/2 : 18
                color:  AppState.accentPill ? AppState.accentPill : Qt.rgba(0.06, 0.06, 0.09, 0.60)
                border.color: AppState.accentBorder ? AppState.accentBorder : Qt.rgba(0.3, 0.3, 0.6, 0.25); border.width: 1
                Behavior on radius { NumberAnimation { duration: 200 } }

                Rectangle {
                    anchors.fill: parent; anchors.margins: -4
                    radius: parent.radius + 4; color: "transparent"
                    border.color: Qt.rgba(0,0,0,0.35); border.width: 4; z: -1
                    opacity: win.pillOp >= 0.99 && !win.dualMode ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 60 } }
                }
            }

            // Key handler
            Item {
                id: keyItem
                anchors.fill: parent; focus: true
                Keys.onUpPressed:     { win.pressUp() }
                Keys.onDownPressed:   { win.pressDown() }
                Keys.onEscapePressed: { win.pressDown() }
                Keys.onLeftPressed: {
                    if (!win.busy && !win.dualMode && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat + 3) % 4
                        win.pillH    = win.catExpandH(win.frontCat)
                    }
                }
                Keys.onRightPressed: {
                    if (!win.busy && !win.dualMode && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat + 1) % 4
                        win.pillH    = win.catExpandH(win.frontCat)
                    }
                }
            }

            // Conteúdo modo 1/2 (expandido)
            Item {
                visible: !win.dualMode
                anchors.fill: parent
                opacity: frontPill.height > 70 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 100 } }

                // Dots
                Row {
                    id: dotsRow
                    anchors.top: parent.top; anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            width:  win.frontCat===index ? 16 : 5; height: 5; radius: 2.5
                            color:  win.frontCat===index ? "white" : Qt.rgba(1,1,1,0.25)
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                            Behavior on color { ColorAnimation  { duration: 150 } }
                        }
                    }
                }

                Item {
                    anchors.top: dotsRow.bottom; anchors.topMargin: 8
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    clip: true
                    ExpandedContent { catIndex: win.frontCat }
                }
            }

            // Conteúdo modo 2/2 (compacto)
            CompactContent {
                visible:      win.dualMode
                anchors.fill: parent
                anchors.margins: 6
                catIndex: win.frontCat
            }
        }
    }

    MouseArea {
        anchors.fill: parent; z: -1
        onClicked: { if (!closeAnim.running) win.pressDown() }
    }

    // ── Pill compacta ─────────────────────────────────────────────────────
    component CompactContent: Item {
        property int catIndex: 0

        Text {
            visible: catIndex === 0
            anchors.centerIn: parent
            color: "white"; font.pixelSize: 13; font.weight: Font.Medium
            Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm") }
        }
        Row {
            visible: catIndex === 1 && mpris.hasPlayer
            anchors.centerIn: parent; spacing: 5
            Text { text: "♫"; color: Qt.rgba(1,1,1,0.7); font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            Text { text: mpris.title||""; color:"white"; font.pixelSize:10; width:100; elide:Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { visible: catIndex===1 && !mpris.hasPlayer; anchors.centerIn:parent; text:"♫"; color:Qt.rgba(1,1,1,0.4); font.pixelSize:14 }
        Row {
            visible: catIndex === 2; anchors.centerIn: parent; spacing: 5
            Text { text:"CPU"; color:Qt.rgba(1,1,1,0.5); font.pixelSize:9; anchors.verticalCenter:parent.verticalCenter }
            Text { text:"–%"; color:"white"; font.pixelSize:13; font.bold:true; anchors.verticalCenter:parent.verticalCenter }
        }
        Row {
            visible: catIndex === 3; anchors.centerIn: parent; spacing: 5
            Text { text:"☁"; font.pixelSize:13; color:Qt.rgba(1,1,1,0.7); anchors.verticalCenter:parent.verticalCenter }
            Text { text:"–°"; color:"white"; font.pixelSize:13; font.bold:true; anchors.verticalCenter:parent.verticalCenter }
        }
    }

    // ── Conteúdo expandido ────────────────────────────────────────────────
    component ExpandedContent: Item {
        id: ec; anchors.fill: parent; property int catIndex: 0

        Column {
            visible: ec.catIndex===0; anchors.centerIn:parent; spacing:2
            Text { anchors.horizontalCenter:parent.horizontalCenter; color:"white"; font.pixelSize:26; font.bold:true
                   Timer{interval:1000;running:true;repeat:true;triggeredOnStart:true;onTriggered:parent.text=Qt.formatTime(new Date(),"HH:mm")} }
            Text { anchors.horizontalCenter:parent.horizontalCenter; text:Qt.formatDate(new Date(),"ddd, dd MMM"); color:Qt.rgba(1,1,1,0.5); font.pixelSize:10 }
        }

        Item {
            visible: ec.catIndex===1; anchors.fill:parent
            Column { visible:!mpris.hasPlayer; anchors.centerIn:parent; spacing:6
                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"♫";color:Qt.rgba(1,1,1,0.2);font.pixelSize:28}
                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"Nenhuma mídia";color:Qt.rgba(1,1,1,0.3);font.pixelSize:11}
            }
            Item { visible:mpris.hasPlayer; anchors.fill:parent
                Row { anchors.top:parent.top; anchors.left:parent.left; anchors.right:parent.right; height:64; spacing:12
                    Rectangle { width:64;height:64;radius:10;color:Qt.rgba(1,1,1,0.06);clip:true
                        Image{anchors.fill:parent;source:mpris.albumArt;fillMode:Image.PreserveAspectCrop;visible:mpris.albumArt!==""}
                        Text{anchors.centerIn:parent;visible:mpris.albumArt==="";text:"♫";color:Qt.rgba(1,1,1,0.25);font.pixelSize:26}
                    }
                    Column { anchors.verticalCenter:parent.verticalCenter; width:parent.width-76; spacing:5
                        Text{width:parent.width;text:mpris.title||"Sem título";color:"white";font.pixelSize:13;font.bold:true;elide:Text.ElideRight}
                        Text{width:parent.width;text:mpris.artist||"";color:Qt.rgba(1,1,1,0.45);font.pixelSize:10;elide:Text.ElideRight}
                        Item{width:parent.width;height:3
                            Rectangle{anchors.fill:parent;radius:2;color:Qt.rgba(1,1,1,0.12)}
                            Rectangle{width:parent.width*mpris.progress;height:parent.height;radius:2;color:"white"
                                Behavior on width{NumberAnimation{duration:1000;easing.type:Easing.Linear}}}
                        }
                        Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:20
                            Text{text:"⏮";color:Qt.rgba(1,1,1,0.55);font.pixelSize:14;MouseArea{anchors.fill:parent;onClicked:mpris.prev()}}
                            Text{text:mpris.playing?"⏸":"▶";color:"white";font.pixelSize:16;MouseArea{anchors.fill:parent;onClicked:mpris.playPause()}}
                            Text{text:"⏭";color:Qt.rgba(1,1,1,0.55);font.pixelSize:14;MouseArea{anchors.fill:parent;onClicked:mpris.next()}}
                        }
                    }
                }
                Row { anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right;height:36;spacing:4
                    Repeater{model:12;delegate:Item{
                        width:(parent.width-44)/12;height:parent.height
                        property real barH:Math.max(3,(win.cavaValues[index]||0)*height)
                        Behavior on barH{NumberAnimation{duration:80;easing.type:Easing.OutCubic}}
                        Rectangle{width:parent.width;height:parent.barH;radius:3;y:parent.height-parent.barH
                            color:Qt.rgba(1,1,1,0.4+(parent.barH/36.0)*0.6)}
                    }}
                }
            }
        }

        Column { visible:ec.catIndex===2; anchors.centerIn:parent; spacing:4
            Text{anchors.horizontalCenter:parent.horizontalCenter;text:"CPU  —  RAM";color:Qt.rgba(1,1,1,0.4);font.pixelSize:9}
            Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:16
                Text{text:"–%";color:"white";font.pixelSize:24;font.bold:true}
                Text{text:"–%";color:Qt.rgba(1,1,1,0.65);font.pixelSize:24;font.bold:true}
            }
        }

        Row { visible:ec.catIndex===3; anchors.centerIn:parent; spacing:10
            Text{anchors.verticalCenter:parent.verticalCenter;text:"☁";font.pixelSize:30;color:Qt.rgba(1,1,1,0.65)}
            Column{anchors.verticalCenter:parent.verticalCenter;spacing:2
                Text{text:"–°";color:"white";font.pixelSize:24;font.bold:true}
                Text{text:"em breve";color:Qt.rgba(1,1,1,0.35);font.pixelSize:9}
            }
        }
    }
}
