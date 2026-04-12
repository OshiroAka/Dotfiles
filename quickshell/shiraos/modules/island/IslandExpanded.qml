import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Controls
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
    implicitHeight: 500
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

    function pillColor()   { return AppState.accentPill   ? AppState.accentPill   : Qt.rgba(0.06,0.06,0.09,0.12) }
    function darkCol()     { return AppState.accentDark   ? AppState.accentDark   : Qt.rgba(0.10,0.08,0.18,0.90) }
    function borderColor() { return AppState.accentBorder ? AppState.accentBorder : Qt.rgba(0.3,0.3,0.6,0.25) }
    function accentCol()   { return AppState.accentColor  ? AppState.accentColor  : Qt.rgba(0.55,0.55,1.0,1.0) }
    function textCol(bright) {
        if (!AppState.accentColor) return "white"
        var c = AppState.accentColor
        return bright
            ? Qt.rgba(c.r*0.7+0.3, c.g*0.7+0.3, c.b*0.7+0.3, 1.0)
            : Qt.rgba(c.r*0.3+0.7, c.g*0.3+0.7, c.b*0.3+0.7, 1.0)
    }

    property int  mode:    0
    property bool busy:    false
    property int  frontCat:   0
    property int  backCat:    0
    property int  overviewSel: 0

    function catExpandH(c) { return c === 1 ? 240 : c === 2 ? 160 : c === 3 ? 200 : 200 }
    function catExpandW(c) { return c === 1 ? 600 : c === 2 ? 420 : c === 3 ? 680 : 420 }
    function catName(c)    { return ["Relogio","Musica","CPU","Clima"][c] }
    function catIcon(c)    { return ["~","~","~","~"][c] }

    property real pillW:  260
    property real pillH:  36
    onPillHChanged: AppState.islandBottom = 8 + pillH + 12
    property real pillOp: 0.0

    property real frontScale:  1.0
    property real frontY:      0.0
    property real frontOpDual: 1.0
    property real backScale:   0.82
    property real backOpacity: 0.0

    property real overviewOp: 0.0
    property real overviewH:  270
    property bool weatherDayMode:  false
    property int  weatherDayIdx:   0
    property bool weatherHourMode: false
    property int  weatherHourIdx:  0

    // Calendário
    property bool calendarMode: false
    property bool lyricsMode: false
    property bool lyricsLoading: false
    property bool lyricsSynced: false
    property var  lyricsLines: []   // [{ms: int, text: string}]
    property var  _lyricsBuffer: []
    Timer {
        id: typeTimer
        interval: 130; repeat: true; running: false
        onTriggered: {
            var full = win.lyricsLines.length > 0 ? (win.lyricsLines[win.lyricsCurrent].text || "").split(" ") : []
            if (win.lyricsTypePos < full.length) win.lyricsTypePos++
            else typeTimer.stop()
        }
    }
    property int  lyricsCurrent: 0
    property int  lyricsCurrentWord: 0
    property int  lyricsTypePos: 0  // índice da linha atual
    property int  lyricsWordIdx: 0   // palavra atual dentro da linha
    property var  lyricsWords: []    // palavras da linha atual
    property int  calDay:   (new Date()).getDate()
    property int  calMonth: (new Date()).getMonth()
    property int  calYear:  (new Date()).getFullYear()
    property int  calSelDay: (new Date()).getDate()

    // Dígitos do relógio para slot machine
    property int tH1: 0; property int tH2: 0
    property int tM1: 0; property int tM2: 0
    property int tS1: 0; property int tS2: 0
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours(); var m = now.getMinutes(); var s = now.getSeconds()
            win.tH1 = Math.floor(h/10); win.tH2 = h%10
            win.tM1 = Math.floor(m/10); win.tM2 = m%10
            win.tS1 = Math.floor(s/10); win.tS2 = s%10
        }
    }

    SequentialAnimation {
        id: openAnim
        PauseAnimation { duration: 80 }
        NumberAnimation { target: win; property: "pillOp"; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; id: openW; property: "pillW";  to: 600; duration: 180; easing.type: Easing.OutExpo }
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
        ScriptAction { script: { win.mode = 0; AppState.islandOpen = false; win.weatherDayMode=false; win.weatherHourMode=false; win.calendarMode=false; win.lyricsMode=false } }
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
                win.mode = 0; win.frontScale = 1.0; win.backScale = 0.82; win.weatherDayMode=false; win.weatherHourMode=false; win.calendarMode=false; win.lyricsMode=false
                win.frontY = 0; win.frontOpDual = 1.0; win.busy = false
                keyItem.forceActiveFocus()
            }
        }
    }

    SequentialAnimation {
        id: enterOverview
        ScriptAction { script: { win.busy = true; win.overviewSel = 0 } }
        ParallelAnimation {
            NumberAnimation { target: win; property: "backOpacity"; to: 0.0; duration: 150 }
            NumberAnimation { target: win; property: "pillW"; to: 380; duration: 200; easing.type: Easing.OutExpo }
            NumberAnimation { target: win; property: "pillH"; to: win.overviewH; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
        }
        NumberAnimation { target: win; property: "overviewOp"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        ScriptAction { script: { win.mode = 2; win.busy = false; keyItem.forceActiveFocus() } }
    }

    SequentialAnimation {
        id: exitOverview
        ScriptAction { script: win.busy = true }
        NumberAnimation { target: win; property: "overviewOp"; to: 0.0; duration: 140; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: win; property: "pillW"; to: 360; duration: 180; easing.type: Easing.InExpo }
            NumberAnimation { id: exitOvH; target: win; property: "pillH"; duration: 220; easing.type: Easing.InBack; easing.overshoot: 0.8 }
        }
        NumberAnimation { target: win; property: "pillW"; to: 360; duration: 180; easing.type: Easing.OutExpo }
        NumberAnimation { id: exitOvExpand; target: win; property: "pillH"; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        ScriptAction { script: { win.mode = 0; win.busy = false; keyItem.forceActiveFocus() } }
    }

    function overviewOtherCat(slot) {
        var others = []
        for (var i = 0; i < 4; i++) if (i !== win.frontCat) others.push(i)
        return others[slot]
    }

    function pressEnter() {
        if (busy || openAnim.running || closeAnim.running) return

        if (mode === 0 && frontCat === 3) {
            if (win.weatherDayMode) { win.weatherHourMode=!win.weatherHourMode; win.pillH=win.weatherHourMode?420:win.catExpandH(3)+80; win.pillW=win.weatherHourMode?900:win.catExpandW(3) }
            return
        }
        if (mode === 0 || mode === 1) {
            if (mode === 1) { backOpacity = 0.0; mode = 0 }
            enterOverview.start()
        } else if (mode === 2) {
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
        if (busy || openAnim.running || closeAnim.running) return
        if (mode === 0 && frontCat === 0) {
            if (win.calendarMode) { win.calendarMode=false; win.pillH=catExpandH(0); win.pillW=catExpandW(0) }
            else { win.calendarMode=true; win.pillH=380; win.pillW=560 }
            return
        }
        if (mode === 0 && frontCat === 1) {
            if (win.lyricsMode) {
                win.lyricsMode = false
                win.pillH = win.catExpandH(1); win.pillW = win.catExpandW(1)
            } else {
                win.lyricsMode = true
                win.pillH = 380; win.pillW = 820
                win._lyricsBuffer = []; win.lyricsLines = []
                win.lyricsCurrent = 0; win.lyricsLoading = true
                lyricsProc.running = false; lyricsProc.running = true
            }
            return
        }
        if (mode === 0 && frontCat === 3) {
            if(win.weatherHourMode){win.weatherHourMode=false;win.pillH=catExpandH(3);win.pillW=catExpandW(3)}
            else if(win.weatherDayMode){win.weatherDayMode=false;win.weatherHourMode=false;win.pillH=win.catExpandH(3);win.pillW=win.catExpandW(3)}
            else{win.weatherDayMode=true;win.weatherDayIdx=0;win.pillH=win.catExpandH(3)+80;win.pillW=760}
            return
        }
        if (mode === 2) {
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

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:  parent.top; anchors.topMargin: 4
        width: 960; height: 480

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

            Item {
                id: keyItem; anchors.fill:parent; focus:true
                Keys.onUpPressed:     { win.pressUp() }
                Keys.onDownPressed:   { win.pressDown() }
                Keys.onEscapePressed: {
                    if (win.calendarMode) { win.calendarMode=false; win.pillH=catExpandH(0); win.pillW=catExpandW(0) } else win.pressDown()
                }
                Keys.onReturnPressed: { win.pressEnter() }
                Keys.onEnterPressed:  { win.pressEnter() }
                Keys.onLeftPressed: function(event) {
                    if (win.mode===0 && win.frontCat===0 && win.calendarMode) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            // Mês anterior
                            var d = new Date(win.calYear, win.calMonth - 1, 1)
                            win.calMonth = d.getMonth(); win.calYear = d.getFullYear()
                            win.calSelDay = 1
                        } else {
                            // Dia anterior
                            var cur = new Date(win.calYear, win.calMonth, win.calSelDay - 1)
                            win.calSelDay = cur.getDate(); win.calMonth = cur.getMonth(); win.calYear = cur.getFullYear()
                        }
                        return
                    }
                    if (win.mode===2) {
                        win.overviewSel = (win.overviewSel + 2) % 3
                    } else if (win.mode===0 && win.weatherHourMode) {
                        win.weatherHourIdx = Math.max(0, win.weatherHourIdx - 1)
                    } else if (win.mode===0 && win.weatherDayMode) {
                        win.weatherDayIdx = (win.weatherDayIdx + 6) % 7
                    } else if (win.mode===0 && !win.busy && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat+3)%4
                        win.pillH    = win.catExpandH(win.frontCat)
                        win.pillW    = win.catExpandW(win.frontCat)
                    }
                }
                Keys.onRightPressed: function(event) {
                    if (win.mode===0 && win.frontCat===0 && win.calendarMode) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            // Próximo mês
                            var d = new Date(win.calYear, win.calMonth + 1, 1)
                            win.calMonth = d.getMonth(); win.calYear = d.getFullYear()
                            win.calSelDay = 1
                        } else {
                            // Próximo dia
                            var cur = new Date(win.calYear, win.calMonth, win.calSelDay + 1)
                            win.calSelDay = cur.getDate(); win.calMonth = cur.getMonth(); win.calYear = cur.getFullYear()
                        }
                        return
                    }
                    if (win.mode===2) {
                        win.overviewSel = (win.overviewSel + 1) % 3
                    } else if (win.mode===0 && win.weatherHourMode) {
                        win.weatherHourIdx = Math.min(23, win.weatherHourIdx + 1)
                    } else if (win.mode===0 && win.weatherDayMode) {
                        win.weatherDayIdx = (win.weatherDayIdx + 1) % 7
                    } else if (win.mode===0 && !win.busy && !openAnim.running && !closeAnim.running) {
                        win.frontCat = (win.frontCat+1)%4
                        win.pillH    = win.catExpandH(win.frontCat)
                        win.pillW    = win.catExpandW(win.frontCat)
                    }
                }
            }

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

            CompactContent {
                visible: win.mode === 1
                anchors.fill:parent; anchors.margins:6; catIndex:win.frontCat
            }

            Item {
                visible: win.mode === 2
                anchors.fill: parent
                opacity: win.overviewOp
                Behavior on opacity { NumberAnimation { duration:150 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Row {
                        width: parent.width; height: 100; spacing: 10

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

                        Rectangle {
                            width: (parent.width - 10) * 0.62; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.55)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=1; win.pressEnter() } }
                            Column { visible:!mpris.hasPlayer; anchors.centerIn:parent; spacing:4
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"♫";color:win.accentCol();font.pixelSize:22}
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"Nenhuma midia";color:Qt.rgba(1,1,1,0.3);font.pixelSize:9}
                            }
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
                                        Text{text:"prev";color:win.accentCol();font.pixelSize:11;MouseArea{anchors.fill:parent;onClicked:mpris.prev()}}
                                        Text{text:mpris.playing?"pause":"play";color:win.textCol(false);font.pixelSize:13;MouseArea{anchors.fill:parent;onClicked:mpris.playPause()}}
                                        Text{text:"next";color:win.accentCol();font.pixelSize:11;MouseArea{anchors.fill:parent;onClicked:mpris.next()}}
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width; height: 70; spacing: 10

                        Rectangle {
                            width: (parent.width - 10) * 0.5; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.30)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=2; win.pressEnter() } }
                            Column { anchors.centerIn:parent; spacing:4
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:"CPU / RAM";color:win.accentCol();font.pixelSize:8}
                                Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:12
                                    Text{text:"-%";color:win.textCol(false);font.pixelSize:18;font.bold:true}
                                    Text{text:"-%";color:Qt.rgba(win.accentCol().r*0.7+0.3,win.accentCol().g*0.7+0.3,win.accentCol().b*0.7+0.3,0.8);font.pixelSize:18;font.bold:true}
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 10) * 0.5; height: parent.height
                            radius: 14
                            color: Qt.rgba(win.accentCol().r*0.18+0.03, win.accentCol().g*0.18+0.03, win.accentCol().b*0.22+0.04, 0.55)
                            border.color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.45); border.width: 1
                            MouseArea { anchors.fill:parent; onClicked:{ win.frontCat=3; win.pressEnter() } }
                            Row { anchors.centerIn:parent; spacing:8
                                Text{anchors.verticalCenter:parent.verticalCenter;text:"~";font.pixelSize:24;color:win.accentCol()}
                                Column{anchors.verticalCenter:parent.verticalCenter;spacing:2
                                    Text{text:"--";color:win.textCol(false);font.pixelSize:20;font.bold:true}
                                    Text{text:"em breve";color:win.accentCol();font.pixelSize:8}
                                }
                            }
                        }
                    }

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


    Process {
        id: lyricsProc
        command: ["/home/oshiro/.local/bin/shiraos-lyrics"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("MODE:SYNCED")) {
                    win.lyricsSynced = true
                } else if (line.startsWith("MODE:PLAIN")) {
                    win.lyricsSynced = false
                } else if (line.startsWith("LINE:")) {
                    var rest = line.slice(5)
                    var sep  = rest.indexOf("|")
                    var ms   = parseInt(rest.slice(0, sep)) || 0
                    var text = rest.slice(sep + 1)
                    var buf  = win._lyricsBuffer.slice()
                    buf.push({ms: ms, text: text})
                    win._lyricsBuffer = buf
                }
            }
        }
        onExited: function(code, status) {
            win.lyricsLoading = false
            if (win._lyricsBuffer.length > 0) {
                win.lyricsLines   = win._lyricsBuffer
                win.lyricsCurrent = 0
                win.lyricsWordIdx = 0
                win.lyricsWords   = win._lyricsBuffer.length > 0 ? win._lyricsBuffer[0].text.split(" ") : []
            } else {
                win.lyricsLines = [{ms:0, text:"Letra não encontrada."}]
            }
        }
    }

    // Posição do Spotify para sync
    Process {
        id: lyricsPosProc
        command: ["/home/oshiro/.local/bin/shiraos-lyrics-pos"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var posMs = (parseInt(line) || 0) + 200
                if (win.lyricsSynced && win.lyricsLines.length > 0) {
                    var lines = win.lyricsLines
                    // Calcula palavra atual dentro da linha
                    if (win.lyricsCurrent < lines.length) {
                        var lineStart = lines[win.lyricsCurrent].ms
                        var lineEnd   = win.lyricsCurrent+1 < lines.length ? lines[win.lyricsCurrent+1].ms : lineStart+4000
                        var words     = (lines[win.lyricsCurrent].text||'').split(' ')
                        var lineDur   = Math.max(1, lineEnd - lineStart)
                        var linePos   = (mpris.position * 1000) - lineStart
                        var wi        = Math.floor((linePos / lineDur) * words.length)
                        win.lyricsCurrentWord = Math.max(0, Math.min(wi, words.length-1))
                    }
                    var idx = 0
                    for (var i = 0; i < lines.length; i++) {
                        if (lines[i].ms <= posMs) idx = i
                        else break
                    }
                    // Atualiza linha
                    if (idx !== win.lyricsCurrent) {
                        win.lyricsCurrent = idx
                        win.lyricsTypePos = 0; typeTimer.restart()
                        win.lyricsWords = lines[idx].text.split(" ")
                        win.lyricsWordIdx = 0
                    }
                    // Calcula palavra atual por interpolação
                    var lineStart = lines[idx].ms
                    var lineEnd   = (idx + 1 < lines.length) ? lines[idx + 1].ms : lineStart + 3000
                    var duration  = lineEnd - lineStart
                    var elapsed   = posMs - lineStart
                    var words     = win.lyricsWords.length
                    if (words > 0 && duration > 0) {
                        var wIdx = Math.floor((elapsed / duration) * words)
                        win.lyricsWordIdx = Math.min(wIdx, words - 1)
                    }
                }
            }
        }
    }

    Timer {
        id: lyricsSyncTimer
        interval: 80; repeat: true; running: win.lyricsMode && win.lyricsSynced && !win.lyricsLoading
        onTriggered: {
            var posMs = Math.round(mpris.position * 1000)
            if (win.lyricsSynced && win.lyricsLines.length > 0) {
                var lines = win.lyricsLines
                // Calcula palavra atual
                if (win.lyricsCurrent < lines.length) {
                    var lineStart = lines[win.lyricsCurrent].ms
                    var lineEnd   = win.lyricsCurrent+1 < lines.length ? lines[win.lyricsCurrent+1].ms : lineStart+4000
                    var words     = (lines[win.lyricsCurrent].text||'').split(' ')
                    var lineDur   = Math.max(1, lineEnd - lineStart)
                    var linePos   = posMs - lineStart
                    var wi        = Math.floor((linePos / lineDur) * words.length)
                    win.lyricsCurrentWord = Math.max(0, Math.min(wi, words.length-1))
                }
                // Acha linha atual
                var idx = 0
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].ms <= posMs) idx = i
                    else break
                }
                if (idx !== win.lyricsCurrent) {
                    win.lyricsCurrent = idx
                    win.lyricsTypePos = 0; typeTimer.restart()
                }
            }
        }
    }

    MouseArea {
        anchors.fill:parent; z:-1
        onClicked: { if (!closeAnim.running) win.pressDown() }
    }

    component SlotD: Item {
        id: sd2
        property int  value:  0
        property int  maxVal: 9
        property real bigPx:  28
        property real smPx:   10
        width: bigPx * 0.75; height: bigPx + smPx * 2 + 24; clip: true
        property real slideY: 0
        onValueChanged: { slideY = 20; sl2.restart() }
        NumberAnimation { id: sl2; target: sd2; property: "slideY"; to: 0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height/2 - bigPx*0.6 - sd2.smPx - 2 - sd2.slideY
            spacing: 2
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: (sd2.value-1+sd2.maxVal+1)%(sd2.maxVal+1)
                   color: Qt.rgba(1,1,1,0.15); font.pixelSize: sd2.smPx; font.family: "monospace" }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: sd2.value; color: win.textCol(false)
                   font.pixelSize: sd2.bigPx; font.weight: Font.Medium; font.family: "monospace" }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: (sd2.value+1)%(sd2.maxVal+1)
                   color: Qt.rgba(1,1,1,0.15); font.pixelSize: sd2.smPx; font.family: "monospace" }
        }
    }

    component ColonD: Column {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined; spacing: 7
        Rectangle { width: 4; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.5) }
        Rectangle { width: 4; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.5) }
    }

    component WeatherIcon: Item {
        property string itype: "CLOUD"
        property color  icol:  "#87CEEB"
        Item{visible:itype==="CLEAR";anchors.fill:parent
            Rectangle{id:wsc;anchors.centerIn:parent;width:20;height:20;radius:10;color:icol
                SequentialAnimation on opacity{loops:Animation.Infinite;running:itype==="CLEAR"
                    NumberAnimation{to:0.7;duration:1200;easing.type:Easing.InOutSine}
                    NumberAnimation{to:1.0;duration:1200;easing.type:Easing.InOutSine}}}
            Repeater{model:8;Rectangle{x:22+Math.cos(index*Math.PI/4)*14-2;y:22+Math.sin(index*Math.PI/4)*14-2;width:4;height:4;radius:2;color:icol;opacity:wsc.opacity*0.8}}}
        Item{visible:itype==="CLOUD"||itype==="PART";anchors.fill:parent
            Rectangle{id:wcl;property real dx:0;x:dx;y:10;width:28;height:14;radius:7;color:icol;opacity:0.9
                SequentialAnimation on dx{loops:Animation.Infinite;running:itype==="CLOUD"||itype==="PART"
                    NumberAnimation{to:4;duration:2000;easing.type:Easing.InOutSine}
                    NumberAnimation{to:0;duration:2000;easing.type:Easing.InOutSine}}}
            Rectangle{x:wcl.dx+6;y:4;width:16;height:14;radius:7;color:icol;opacity:0.9}
            Rectangle{x:wcl.dx+2;y:18;width:6;height:6;radius:3;color:icol;opacity:itype==="PART"?0.5:0}}
        Item{visible:itype==="RAIN";anchors.fill:parent
            Rectangle{x:6;y:4;width:24;height:12;radius:6;color:icol;opacity:0.85}
            Rectangle{x:12;y:0;width:14;height:10;radius:5;color:icol;opacity:0.85}
            Repeater{model:4;Rectangle{property real drop:0;x:8+index*7;y:18+drop;width:2;height:7;radius:1;color:icol
                SequentialAnimation on drop{loops:Animation.Infinite;running:itype==="RAIN";PauseAnimation{duration:index*200}
                    NumberAnimation{from:0;to:10;duration:500;easing.type:Easing.InQuad}NumberAnimation{from:0;to:0;duration:0}}
                SequentialAnimation on opacity{loops:Animation.Infinite;running:itype==="RAIN";PauseAnimation{duration:index*200}
                    NumberAnimation{from:1;to:0;duration:400}NumberAnimation{from:1;to:1;duration:100}}}}}
        Item{visible:itype==="STORM";anchors.fill:parent
            Rectangle{x:4;y:2;width:26;height:13;radius:6;color:"#666";opacity:0.9}
            Rectangle{x:10;y:0;width:16;height:10;radius:5;color:"#666";opacity:0.9}
            Repeater{model:3;Rectangle{property real drop:0;x:8+index*8;y:16+drop;width:2;height:7;radius:1;color:"#888"
                SequentialAnimation on drop{loops:Animation.Infinite;running:itype==="STORM";PauseAnimation{duration:index*200}
                    NumberAnimation{from:0;to:10;duration:500;easing.type:Easing.InQuad}NumberAnimation{from:0;to:0;duration:0}}}}
            Text{x:16;y:13;text:"!";color:icol;font.pixelSize:16;font.bold:true
                SequentialAnimation on opacity{loops:Animation.Infinite;running:itype==="STORM"
                    NumberAnimation{to:0.1;duration:400}NumberAnimation{to:1;duration:100}
                    NumberAnimation{to:0.1;duration:900}NumberAnimation{to:1;duration:100}}}}
        Item{visible:itype==="SNOW";anchors.fill:parent
            Repeater{model:5;Text{property real fall:0;x:4+index*8;y:fall;text:"*";color:icol;font.pixelSize:10
                SequentialAnimation on fall{loops:Animation.Infinite;running:itype==="SNOW";PauseAnimation{duration:index*300}
                    NumberAnimation{from:0;to:34;duration:1500;easing.type:Easing.InQuad}NumberAnimation{from:0;to:0;duration:0}}}}}
        Item{visible:itype==="FOG";anchors.fill:parent
            Rectangle{y:8;width:30;height:3;radius:2;color:icol;opacity:0.5
                SequentialAnimation on x{loops:Animation.Infinite;running:itype==="FOG"
                    NumberAnimation{to:6;duration:2000;easing.type:Easing.InOutSine}NumberAnimation{to:0;duration:2000;easing.type:Easing.InOutSine}}}
            Rectangle{y:18;width:24;height:3;radius:2;color:icol;opacity:0.5
                SequentialAnimation on x{loops:Animation.Infinite;running:itype==="FOG"
                    NumberAnimation{to:4;duration:2500;easing.type:Easing.InOutSine}NumberAnimation{to:0;duration:2500;easing.type:Easing.InOutSine}}}
            Rectangle{y:28;width:20;height:3;radius:2;color:icol;opacity:0.5
                SequentialAnimation on x{loops:Animation.Infinite;running:itype==="FOG"
                    NumberAnimation{to:8;duration:3000;easing.type:Easing.InOutSine}NumberAnimation{to:0;duration:3000;easing.type:Easing.InOutSine}}}}
    }

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
               Text{text:"-%";color:win.textCol(false);font.pixelSize:13;font.bold:true;anchors.verticalCenter:parent.verticalCenter} }
        Text { visible:catIndex===3; anchors.centerIn:parent; text:"~"; color:win.accentCol(); font.pixelSize:14 }
    }

    component ExpandedContent: Item {
        id: ec; anchors.fill:parent; property int catIndex:0

        // ── Cat 0: Relogio + Calendario ──────────────────────────────────
        Item {
            visible: ec.catIndex === 0
            anchors.fill: parent

            // ── Modo normal: relógio ──────────────────────────────────────
            Item {
                visible: !win.calendarMode
                anchors.fill: parent
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        SlotD { value: win.tH1; maxVal: 2; bigPx: 28; smPx: 10 }
                        SlotD { value: win.tH2; maxVal: 9; bigPx: 28; smPx: 10 }
                        ColonD { height: 80 }
                        Item { width: 2; height: 1 }
                        SlotD { value: win.tM1; maxVal: 5; bigPx: 28; smPx: 10 }
                        SlotD { value: win.tM2; maxVal: 9; bigPx: 28; smPx: 10 }
                        ColonD { height: 80 }
                        SlotD { value: win.tS1; maxVal: 5; bigPx: 28; smPx: 10 }
                        SlotD { value: win.tS2; maxVal: 9; bigPx: 28; smPx: 10 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                        color: Qt.rgba(1,1,1,0.55); font.pixelSize: 13
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "↓  calendário"
                        color: Qt.rgba(1,1,1,0.18); font.pixelSize: 10
                    }
                }
            }

            // ── Modo calendário ───────────────────────────────────────────
            Item {
                id: calRoot
                visible: win.calendarMode
                anchors.fill: parent
                anchors.margins: 14

                // Propriedades do calendário no Item pai (acessíveis pelo delegate)
                property int calFW:  new Date(win.calYear, win.calMonth, 1).getDay()
                property int calDIM: new Date(win.calYear, win.calMonth+1, 0).getDate()
                property int todayD: (new Date()).getDate()
                property int todayM: (new Date()).getMonth()
                property int todayY: (new Date()).getFullYear()

                // Cabeçalho mês/ano
                Row {
                    id: calHdr
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Text {
                        text: "‹"; color: win.accentCol()
                        font.pixelSize: 22; font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; onClicked: {
                            var d = new Date(win.calYear, win.calMonth - 1, 1)
                            win.calMonth = d.getMonth(); win.calYear = d.getFullYear(); win.calSelDay = 1
                        }}
                    }
                    Text {
                        text: ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
                               "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"][win.calMonth] + "  " + win.calYear
                        color: "white"; font.pixelSize: 17; font.bold: true
                        renderType: Text.QtRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "›"; color: win.accentCol()
                        font.pixelSize: 22; font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; onClicked: {
                            var d = new Date(win.calYear, win.calMonth + 1, 1)
                            win.calMonth = d.getMonth(); win.calYear = d.getFullYear(); win.calSelDay = 1
                        }}
                    }
                }

                // Dias da semana
                Row {
                    id: calDow
                    anchors.top: calHdr.bottom; anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: ["D","S","T","Q","Q","S","S"]
                        Text {
                            width: 72; horizontalAlignment: Text.AlignHCenter
                            text: modelData; font.pixelSize: 13; font.bold: true
                            renderType: Text.QtRendering
                            color: index===0 ? Qt.rgba(1,0.4,0.4,0.7) : Qt.rgba(1,1,1,0.35)
                        }
                    }
                }

                // Grid dias
                Grid {
                    anchors.top: calDow.bottom; anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7; spacing: 0

                    Repeater {
                        model: calRoot.calFW + calRoot.calDIM +
                               (7 - (calRoot.calFW + calRoot.calDIM) % 7) % 7
                        delegate: Item {
                            width: 72; height: 40
                            property int  day:     index - calRoot.calFW + 1
                            property bool valid:   day >= 1 && day <= calRoot.calDIM
                            property bool isSel:   valid && day === win.calSelDay
                            property bool isToday: valid && day === calRoot.todayD &&
                                                   win.calMonth === calRoot.todayM &&
                                                   win.calYear  === calRoot.todayY

                            Rectangle {
                                anchors.centerIn: parent
                                width: 56; height: 32; radius: 10
                                color: isSel
                                    ? Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.35)
                                    : isToday ? Qt.rgba(1,1,1,0.12) : "transparent"
                                border.color: isSel ? win.accentCol()
                                            : isToday ? Qt.rgba(1,1,1,0.35) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: valid; text: day
                                font.pixelSize: 16; font.bold: isSel || isToday
                                renderType: Text.QtRendering
                                color: isSel ? win.accentCol()
                                           : isToday ? "white"
                                           : (index%7===0) ? Qt.rgba(1,0.5,0.5,0.8)
                                           : Qt.rgba(1,1,1,0.65)
                            }
                            MouseArea {
                                anchors.fill: parent; enabled: valid
                                onClicked: win.calSelDay = day
                            }
                        }
                    }
                }

                // GIF no canto inferior direito
                AnimatedImage {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                    anchors.right: parent.right; anchors.rightMargin: 4
                    width: 52; height: 52
                    source: "file:///home/oshiro/Pictures/gif/8dd176c04a07c37b80a640dbc73382ff.gif"
                    fillMode: Image.PreserveAspectCrop
                    playing: true; smooth: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: 52; height: 52; radius: 10
                                visible: false
                            }
                        }
                    }
                }

                // Data selecionada
                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    text: Qt.formatDate(new Date(win.calYear, win.calMonth, win.calSelDay), "dddd, dd 'de' MMMM 'de' yyyy")
                    color: Qt.rgba(win.accentCol().r*0.3+0.7, win.accentCol().g*0.3+0.7, win.accentCol().b*0.3+0.7, 0.75)
                    font.pixelSize: 12
                    renderType: Text.QtRendering
                }
            }
        }

        // ── Cat 1: Musica (Vinyl) ─────────────────────────────────────────
        Item {
            visible: ec.catIndex === 1
            anchors.fill: parent

            // ── Overlay Lyrics (Karaoke) ─────────────────────────────────
            Item {
                id: lyricsOverlay
                visible: win.lyricsMode
                anchors.fill: parent
                clip: true
                z: 10

                                        Item {
                                    visible: !win.lyricsLoading && win.lyricsLines.length > 0
                                    anchors.fill: parent
                                    clip: true
                
                                    ListView {
                                        id: lyricsView
                                        anchors.fill: parent
                                        model: win.lyricsLines
                                        clip: true
                                        interactive: false
                                        spacing: 18
                
                                        preferredHighlightBegin: height / 2 - 50
                                        preferredHighlightEnd:   height / 2 + 50
                                        highlightRangeMode: ListView.StrictlyEnforceRange
                                        currentIndex: win.lyricsCurrent
                                        highlightMoveDuration: 1800
                                        highlightMoveVelocity: -1
                
                        delegate: Item {
                            id: lyricDelegate
                            width: lyricsView.width
                            property bool isCurrent: index === win.lyricsCurrent
                            property real dist: Math.abs(index - win.lyricsCurrent)
                            property bool isBelow: index > win.lyricsCurrent
                            opacity: isBelow ? 0.0 : dist === 0 ? 1.0 : dist === 1 ? 0.38 : dist === 2 ? 0.12 : 0.0
                            height: isCurrent ? 100 : 48
                            Behavior on height  { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

                            // Linha não-atual
                            Text {
                                visible: !isCurrent
                                anchors.centerIn: parent
                                width: parent.width - 48
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                renderType: Text.QtRendering
                                text: modelData.text || ""
                                font.pixelSize: 15
                                color: "white"
                            }

                            // Linha atual
                            Item {
                                visible: isCurrent
                                anchors.centerIn: parent
                                width: parent.width - 32
                                height: parent.height

                                // Glow externo (halo largo — fica ilegível pelo blurMax alto)
                                Text {
                                    anchors.centerIn: parent; width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap; renderType: Text.QtRendering
                                    text: modelData.text || ""
                                    font.pixelSize: 34; font.bold: true
                                    color: win.accentCol()
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        autoPaddingEnabled: true
                                        blurEnabled: true
                                        blur: 1.0; blurMax: 128; blurMultiplier: 1.8
                                    }
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite; running: isCurrent
                                        NumberAnimation { to: 0.6; duration: 900; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                    }
                                }

                                // Glow interno (halo mais próximo, branco)
                                Text {
                                    anchors.centerIn: parent; width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap; renderType: Text.QtRendering
                                    text: modelData.text || ""
                                    font.pixelSize: 34; font.bold: true
                                    color: "white"; opacity: 0.8
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        autoPaddingEnabled: true
                                        blurEnabled: true
                                        blur: 1.0; blurMax: 32; blurMultiplier: 1.2
                                    }
                                }

                                // Texto nítido por cima (sem blur)
                                Text {
                                    anchors.centerIn: parent; width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap; renderType: Text.QtRendering
                                    text: modelData.text || ""
                                    font.pixelSize: 32; font.bold: true
                                    color: "white"
                                }
                            }
                        }




                                    }
                
                                    // Fade topo
                                    Rectangle {
                                        anchors.top: parent.top; width: parent.width; height: 52; z: 2
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: win.pillColor() }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }
                                    // Fade base
                                    Rectangle {
                                        anchors.bottom: parent.bottom; width: parent.width; height: 52; z: 2
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 1.0; color: win.pillColor() }
                                        }
                                    }
                                }


                // Loading
                Text {
                    visible: win.lyricsLoading
                    anchors.centerIn: parent
                    text: "Buscando letra..."
                    color: Qt.rgba(1,1,1,0.40); font.pixelSize: 13
                    renderType: Text.QtRendering
                }
            }
            clip: true

            Column {
                visible: !mpris.hasPlayer && !win.lyricsMode
                anchors.centerIn: parent; spacing: 6
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"♫"; color:win.accentCol(); font.pixelSize:28 }
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"Nenhuma midia"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:11 }
            }

            Item {
                visible: mpris.hasPlayer && !win.lyricsMode
                anchors.fill: parent

                Text {
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.topMargin: 6; anchors.rightMargin: 10
                    text: "Vinyl"
                    color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.75)
                    font.pixelSize: 11; font.italic: true; font.letterSpacing: 1.5
                }

                Item {
                    id: vinylDisc
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 8
                    width: Math.min(parent.height - 8, parent.width * 0.38)
                    height: width

                    NumberAnimation on rotation {
                        from: 0; to: 360; duration: 5000
                        loops: Animation.Infinite; running: mpris.playing
                        easing.type: Easing.Linear
                    }

                    Rectangle { anchors.fill:parent; radius:width/2; color:"#111111" }

                    Repeater {
                        model: 8
                        Rectangle {
                            anchors.centerIn: parent
                            property real s: 0.92 - index * 0.06
                            width: vinylDisc.width * s; height: width; radius: width/2
                            color: "transparent"
                            border.color: Qt.rgba(1,1,1, 0.04 + index*0.01); border.width: 1
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width*0.50; height: width; radius: width/2; clip: true
                        color: Qt.rgba(0.1,0.1,0.1,1)
                        Image {
                            anchors.fill: parent; source: mpris.albumArt||""
                            fillMode: Image.PreserveAspectCrop
                            visible: mpris.albumArt !== ""; smooth: true
                        }
                        Text {
                            anchors.centerIn: parent; visible: mpris.albumArt===""
                            text:"♫"; color:win.accentCol(); font.pixelSize:22
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent; width:10; height:10; radius:5
                        color:"#222222"; border.color:win.accentCol(); border.width:1
                    }

                    Repeater {
                        model: 24
                        Item {
                            anchors.centerIn: parent
                            width: vinylDisc.width; height: vinylDisc.height
                            rotation: index * 15
                            property real barH: Math.max(2, (win.cavaValues[index % 12]||0) * vinylDisc.width * 0.14)
                            Behavior on barH { NumberAnimation { duration:80; easing.type:Easing.OutCubic } }
                            Rectangle {
                                x: parent.width/2 - width/2; y: 1
                                width: 3; height: parent.barH; radius: 2
                                color: Qt.rgba(win.accentCol().r*0.5+0.5, win.accentCol().g*0.5+0.5, win.accentCol().b*0.5+0.5, 0.7)
                            }
                        }
                    }
                }

                Column {
                    anchors.left: vinylDisc.right; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Text {
                        width: parent.width; text: mpris.title||"Sem titulo"
                        color: win.textCol(false); font.pixelSize:13; font.bold:true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width; text: mpris.artist||""
                        color: win.accentCol(); font.pixelSize:10; elide: Text.ElideRight
                    }

                    Item {
                        width: parent.width; height: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height:3; radius:2
                            color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.20)
                        }
                        Rectangle {
                            id: vinylFill
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * (mpris.progress||0)
                            height:3; radius:2; color: win.accentCol()
                            Behavior on width { NumberAnimation { duration:1000; easing.type:Easing.Linear } }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: vinylFill.width - 4
                            width:8; height:8; radius:4
                            color: win.textCol(false)
                            border.color: win.accentCol(); border.width:1
                        }
                    }

                    Row {
                        width: parent.width; height: 24; spacing: 2
                        Repeater {
                            model: 20
                            Item {
                                width: (parent.width - 19*2) / 20; height: 24
                                property real bh: 0.2
                                SequentialAnimation on bh {
                                    loops: Animation.Infinite; running: mpris.playing
                                    NumberAnimation { to: 0.25+(index%5)*0.15; duration:160+(index*41)%200; easing.type:Easing.InOutSine }
                                    NumberAnimation { to: 0.06+(index%3)*0.07; duration:130+(index*31)%170; easing.type:Easing.InOutSine }
                                }
                                NumberAnimation on bh {
                                    running: !mpris.playing; to:0.12+(index%4)*0.04
                                    duration:500; easing.type:Easing.OutCubic
                                }
                                Rectangle {
                                    width: parent.width; height: parent.height * parent.bh
                                    anchors.bottom: parent.bottom; radius: width/2
                                    color: Qt.rgba(win.accentCol().r, win.accentCol().g, win.accentCol().b, 0.55+(index%3)*0.1)
                                }
                            }
                        }
                    }

                    Row {
                        spacing: 16
                        Text {
                            text:"prev"; color:win.accentCol(); font.pixelSize:14
                            MouseArea{id:vPrev;anchors.fill:parent;onClicked:mpris.prev()}
                        }
                        Text {
                            text:mpris.playing?"pause":"play"; color:win.textCol(false); font.pixelSize:18
                            MouseArea{id:vPP;anchors.fill:parent;onClicked:mpris.playPause()}
                        }
                        Text {
                            text:"next"; color:win.accentCol(); font.pixelSize:14
                            MouseArea{id:vNext;anchors.fill:parent;onClicked:mpris.next()}
                        }
                    }
                }
            }
        }

        // ── Cat 2: CPU / RAM / Disco ──────────────────────────────────────
        Item {
            id: sysData
            visible: ec.catIndex === 2
            anchors.fill: parent
            clip: true

            property real cpuVal:  0
            property real ramVal:  0
            property real diskVal: 0
            property string ramUsed: "-"

            Process {
                id: sysProc
                command: ["/home/oshiro/.local/bin/shiraos-sysinfo"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        var parts = line.trim().split(" ")
                        for (var i = 0; i < parts.length; i++) {
                            var kv = parts[i].split(":")
                            if (kv[0] === "CPU")  sysData.cpuVal  = Math.min(100, parseInt(kv[1])||0) / 100
                            if (kv[0] === "RAM")  sysData.ramVal  = Math.min(100, parseInt(kv[1])||0) / 100
                            if (kv[0] === "DISK") sysData.diskVal = Math.min(100, parseInt(kv[1])||0) / 100
                            if (kv[0] === "RU")   sysData.ramUsed = kv[1] || "-"
                        }
                    }
                }
            }
            Timer {
                interval: 2000; running: ec.catIndex === 2; repeat: true; triggeredOnStart: true
                onTriggered: { sysProc.running = false; sysProc.running = true }
            }

            Row {
                anchors.centerIn: parent
                spacing: 18

                Item {
                    width: 90; height: 100; anchors.verticalCenter: parent.verticalCenter
                    Canvas {
                        id: cpuCanvas
                        anchors.top: parent.top; width: 90; height: 90
                        property real val: sysData.cpuVal
                        onValChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"), cx=45, cy=45, r=36, lw=7
                            var s = Math.PI*0.75, e = Math.PI*2.25
                            ctx.clearRect(0,0,width,height)
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,e); ctx.strokeStyle=Qt.rgba(1,1,1,0.08); ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                            var col = val<0.6?"#00e5ff":val<0.85?"#ffb300":"#ff3d00"
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,s+(e-s)*val); ctx.strokeStyle=col; ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                        }
                        Text { anchors.centerIn:parent; text:Math.round(sysData.cpuVal*100)+"%"; color:"white"; font.pixelSize:14; font.bold:true }
                    }
                    Text { anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; text:"CPU"; color:Qt.rgba(1,1,1,0.5); font.pixelSize:10 }
                }

                Item {
                    width: 90; height: 100; anchors.verticalCenter: parent.verticalCenter
                    Canvas {
                        id: ramCanvas
                        anchors.top: parent.top; width: 90; height: 90
                        property real val: sysData.ramVal
                        onValChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"), cx=45, cy=45, r=36, lw=7
                            var s = Math.PI*0.75, e = Math.PI*2.25
                            ctx.clearRect(0,0,width,height)
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,e); ctx.strokeStyle=Qt.rgba(1,1,1,0.08); ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                            var col = val<0.6?"#69ff47":val<0.85?"#ffb300":"#ff3d00"
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,s+(e-s)*val); ctx.strokeStyle=col; ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                        }
                        Column {
                            anchors.centerIn: parent; spacing: 0
                            Text { anchors.horizontalCenter:parent.horizontalCenter; text:Math.round(sysData.ramVal*100)+"%"; color:"white"; font.pixelSize:13; font.bold:true }
                            Text { anchors.horizontalCenter:parent.horizontalCenter; text:sysData.ramUsed+"M"; color:Qt.rgba(1,1,1,0.45); font.pixelSize:8 }
                        }
                    }
                    Text { anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; text:"Memory"; color:Qt.rgba(1,1,1,0.5); font.pixelSize:10 }
                }

                Item {
                    width: 90; height: 100; anchors.verticalCenter: parent.verticalCenter
                    Canvas {
                        id: diskCanvas
                        anchors.top: parent.top; width: 90; height: 90
                        property real val: sysData.diskVal
                        onValChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"), cx=45, cy=45, r=36, lw=7
                            var s = Math.PI*0.75, e = Math.PI*2.25
                            ctx.clearRect(0,0,width,height)
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,e); ctx.strokeStyle=Qt.rgba(1,1,1,0.08); ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                            var col = val<0.6?"#e040fb":val<0.85?"#ffb300":"#ff3d00"
                            ctx.beginPath(); ctx.arc(cx,cy,r,s,s+(e-s)*val); ctx.strokeStyle=col; ctx.lineWidth=lw; ctx.lineCap="round"; ctx.stroke()
                        }
                        Text { anchors.centerIn:parent; text:Math.round(sysData.diskVal*100)+"%"; color:"white"; font.pixelSize:14; font.bold:true }
                    }
                    Text { anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; text:"Disk"; color:Qt.rgba(1,1,1,0.5); font.pixelSize:10 }
                }
            }
        }

        // ── Cat 3: Clima ──────────────────────────────────────────────────
        Item {
            id: weatherData
            visible: ec.catIndex === 3
            anchors.fill:parent; clip:true

            property string region:  "..."
            property string tempNow: "--"
            property string condNow: "--"
            property var    days:    []
            property var    hours:   []
            property bool   loaded:  false

            function condIcon(c) {
                var s=(c||"").toLowerCase()
                if(s.indexOf("clear")>=0||s.indexOf("sun")>=0) return "CLEAR"
                if(s.indexOf("mainly")>=0||s.indexOf("partly")>=0) return "PART"
                if(s.indexOf("thunder")>=0||s.indexOf("storm")>=0) return "STORM"
                if(s.indexOf("snow")>=0) return "SNOW"
                if(s.indexOf("rain")>=0||s.indexOf("shower")>=0||s.indexOf("drizzle")>=0) return "RAIN"
                if(s.indexOf("fog")>=0||s.indexOf("mist")>=0) return "FOG"
                return "CLOUD"
            }
            function condColor(c) {
                var s=(c||"").toLowerCase()
                if(s.indexOf("clear")>=0||s.indexOf("sun")>=0) return "#FFD700"
                if(s.indexOf("mainly")>=0||s.indexOf("partly")>=0) return "#87CEEB"
                if(s.indexOf("storm")>=0||s.indexOf("thunder")>=0) return "#FF6B35"
                if(s.indexOf("snow")>=0) return "#E0F0FF"
                if(s.indexOf("rain")>=0||s.indexOf("shower")>=0||s.indexOf("drizzle")>=0) return "#5B9BD5"
                if(s.indexOf("fog")>=0||s.indexOf("mist")>=0) return "#AAAAAA"
                return win.accentCol()
            }

            Process {
                id: weatherProc; running:false
                command:["/home/oshiro/.local/bin/shiraos-weather"]
                stdout: SplitParser { onRead: function(line) {
                    if(line.startsWith("REGION:")) { weatherData.region=line.slice(7) }
                    else if(line.startsWith("NOW:"))  { var p=line.slice(4).split("|"); weatherData.tempNow=p[0]; weatherData.condNow=p[1] }
                    else if(line.startsWith("DAY:"))  { var p=line.slice(4).split("|"); var d=weatherData.days.slice(); d.push({name:p[0],tmin:p[1],tmax:p[2],cond:p[3],prec:p[4]}); weatherData.days=d; weatherData.loaded=true }
                    else if(line.startsWith("HOUR:")) { var p=line.slice(5).split("|"); var h=weatherData.hours.slice(); h.push({date:p[0],hour:p[1],temp:p[2],cond:p[3],prec:p[4]}); weatherData.hours=h }
                }}
            }
            Timer{interval:200;running:true;repeat:false;onTriggered:{weatherProc.running=true}}
            Timer{interval:1800000;running:true;repeat:true;onTriggered:{
                weatherData.days=[];weatherData.hours=[];weatherData.loaded=false
                weatherProc.running=false;weatherProc.running=true}}

            Column{
                visible:!win.weatherDayMode
                anchors.fill:parent;anchors.margins:16;spacing:16
                Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:14
                    Text{text:weatherData.region;color:win.accentCol();font.pixelSize:24;font.bold:true;anchors.verticalCenter:parent.verticalCenter}
                    Text{text:weatherData.tempNow+"°C";color:win.textCol(false);font.pixelSize:22;anchors.verticalCenter:parent.verticalCenter}
                    Text{text:weatherData.condNow;color:Qt.rgba(1,1,1,0.55);font.pixelSize:15;anchors.verticalCenter:parent.verticalCenter}
                }
                Row{width:parent.width;spacing:0
                    Repeater{model:Math.min(7,weatherData.days.length);delegate:Column{
                        width:parent.width/Math.min(7,weatherData.days.length);spacing:6
                        property var d:weatherData.days[index]
                        Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.name:"--";color:Qt.rgba(1,1,1,0.5);font.pixelSize:11}
                        WeatherIcon{anchors.horizontalCenter:parent.horizontalCenter;width:44;height:44
                            itype:d?weatherData.condIcon(d.cond):"CLOUD";icol:d?weatherData.condColor(d.cond):win.accentCol()}
                        Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.tmax+"°":"--";color:win.textCol(false);font.pixelSize:16;font.bold:true}
                        Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.tmin+"°":"--";color:Qt.rgba(1,1,1,0.4);font.pixelSize:13}
                    }}
                }
                Text{anchors.horizontalCenter:parent.horizontalCenter
                    text:weatherData.loaded?"↓  selecionar dia":"Carregando..."
                    color:Qt.rgba(1,1,1,0.2);font.pixelSize:10}
            }

            Item{
                visible:win.weatherDayMode && !win.weatherHourMode
                anchors.fill:parent;anchors.margins:12
                Column{anchors.centerIn:parent;spacing:14
                    Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:0
                        Repeater{model:Math.min(7,weatherData.days.length);delegate:Item{
                            width:100;height:110
                            property var  d:weatherData.days[index]
                            property bool sel:index===win.weatherDayIdx
                            Rectangle{anchors.fill:parent;anchors.margins:3;radius:10
                                color:sel?Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.2):Qt.rgba(1,1,1,0.04)
                                border.color:sel?win.accentCol():"transparent";border.width:1
                                Behavior on color{ColorAnimation{duration:150}}}
                            Column{anchors.centerIn:parent;spacing:4
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.name:"--";color:sel?win.accentCol():Qt.rgba(1,1,1,0.5);font.pixelSize:11;font.bold:sel}
                                WeatherIcon{anchors.horizontalCenter:parent.horizontalCenter;width:42;height:42
                                    itype:d?weatherData.condIcon(d.cond):"CLOUD";icol:d?weatherData.condColor(d.cond):win.accentCol()}
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.tmax+"°":"--";color:sel?win.textCol(false):Qt.rgba(1,1,1,0.4);font.pixelSize:13;font.bold:sel}
                                Text{anchors.horizontalCenter:parent.horizontalCenter;text:d?d.tmin+"°":"--";color:Qt.rgba(1,1,1,0.3);font.pixelSize:11}
                            }
                        }}
                    }
                    Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:20
                        Text{text:"← → navegar";color:Qt.rgba(1,1,1,0.2);font.pixelSize:9}
                        Text{text:"↵  ver horas";color:Qt.rgba(1,1,1,0.2);font.pixelSize:9}
                        Text{text:"↓  fechar";color:Qt.rgba(1,1,1,0.2);font.pixelSize:9}
                    }
                }
            }

            Item {
                id: hourView
                visible: win.weatherDayMode && win.weatherHourMode
                anchors.fill: parent; anchors.margins: 14
                property var selDay: weatherData.days.length > win.weatherDayIdx ? weatherData.days[win.weatherDayIdx] : null
                property var dayHours: {
                    var r=[], base=win.weatherDayIdx*24
                    for(var i=base;i<base+24&&i<weatherData.hours.length;i++) r.push(weatherData.hours[i])
                    return r
                }
                Row {
                    id: hvHdr
                    anchors.top: parent.top; anchors.topMargin: 6; anchors.left: parent.left
                    spacing: 10; height: 26
                    Text { text: hourView.selDay?hourView.selDay.name:"--"; color:win.accentCol(); font.pixelSize:18; font.bold:true; anchors.verticalCenter:parent.verticalCenter }
                    Text { text: hourView.selDay?hourView.selDay.tmax+"° / "+hourView.selDay.tmin+"°":"--"; color:win.textCol(false); font.pixelSize:14; anchors.verticalCenter:parent.verticalCenter }
                    Text { text: hourView.selDay?hourView.selDay.cond:"--"; color:Qt.rgba(1,1,1,0.45); font.pixelSize:12; anchors.verticalCenter:parent.verticalCenter }
                }
                Row {
                    id: hvMain
                    anchors.top: hvHdr.bottom; anchors.topMargin: 10; anchors.left: parent.left; anchors.leftMargin: 4
                    spacing: 14; height: 80
                    WeatherIcon {
                        anchors.verticalCenter: parent.verticalCenter; width:64; height:64
                        itype: hourView.selDay?weatherData.condIcon(hourView.selDay.cond):"CLOUD"
                        icol:  hourView.selDay?weatherData.condColor(hourView.selDay.cond):win.accentCol()
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing:2
                        Text { text:(hourView.dayHours&&hourView.dayHours.length>0)?hourView.dayHours[0].temp+"°":"--"; color:win.textCol(false); font.pixelSize:44; font.bold:true }
                        Text { text:hourView.selDay?hourView.selDay.cond:"--"; color:Qt.rgba(1,1,1,0.40); font.pixelSize:11 }
                    }
                }
                Item {
                    anchors.top: hvHdr.bottom; anchors.topMargin: 10
                    anchors.left: hvMain.right; anchors.leftMargin: 16
                    anchors.right: parent.right; height: 80
                    Text {
                        text: "ShiraOS"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter
                        color:Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.28)
                        font.pixelSize:20; font.bold:true; font.letterSpacing:3
                    }
                    AnimatedImage {
                        anchors.right:parent.right; anchors.rightMargin:8; anchors.verticalCenter:parent.verticalCenter
                        width:68; height:68
                        source: "file:///home/oshiro/Pictures/gif/8dd176c04a07c37b80a640dbc73382ff.gif"
                        fillMode:Image.PreserveAspectCrop; playing:true; smooth:true
                        visible: source !== "file:///home/oshiro/Pictures/gif/"
                    }
                }
                Rectangle { id: hvDiv; anchors.top:hvMain.bottom; anchors.topMargin:8; width:parent.width; height:1; color:Qt.rgba(1,1,1,0.10) }
                Flickable {
                    id: hvFlick
                    anchors.top:hvDiv.bottom; anchors.topMargin:8; anchors.bottom:hvHints.top; anchors.bottomMargin:4
                    anchors.left:parent.left; anchors.right:parent.right
                    clip:true; contentWidth:hvRow.width; flickableDirection:Flickable.HorizontalFlick
                    contentX: Math.max(0, Math.min(win.weatherHourIdx*60 - width/2+28, Math.max(0,contentWidth-width)))
                    Behavior on contentX { NumberAnimation { duration:200; easing.type:Easing.OutCubic } }
                    Row {
                        id: hvRow; height:hvFlick.height; spacing:4
                        Repeater {
                            model: hourView.dayHours?hourView.dayHours.length:0
                            delegate: Item {
                                width:56; height:hvRow.height
                                property var h: hourView.dayHours[index]
                                Rectangle {
                                    anchors.fill:parent; anchors.margins:2; radius:10
                                    color: index===win.weatherHourIdx?Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.18):Qt.rgba(1,1,1,0.05)
                                    border.color: index===win.weatherHourIdx?win.accentCol():Qt.rgba(1,1,1,0.08)
                                    border.width: index===win.weatherHourIdx?2:1
                                }
                                Column {
                                    anchors.centerIn:parent; spacing:5
                                    Text { anchors.horizontalCenter:parent.horizontalCenter; text:h?h.temp+"°":"--"; color:win.textCol(false); font.pixelSize:13; font.bold:true }
                                    WeatherIcon { anchors.horizontalCenter:parent.horizontalCenter; width:26; height:26; itype:h?weatherData.condIcon(h.cond):"CLOUD"; icol:h?weatherData.condColor(h.cond):win.accentCol() }
                                    Text { anchors.horizontalCenter:parent.horizontalCenter; text:h?h.hour.slice(0,5):""; color:Qt.rgba(1,1,1,0.35); font.pixelSize:9 }
                                }
                            }
                        }
                    }
                }
                Row {
                    id: hvHints; anchors.bottom:parent.bottom; anchors.horizontalCenter:parent.horizontalCenter; spacing:20; height:16
                    Text { text:"← → navegar horas"; color:Qt.rgba(1,1,1,0.2); font.pixelSize:9 }
                    Text { text:"↵ / ↓  fechar"; color:Qt.rgba(1,1,1,0.2); font.pixelSize:9 }
                }
            }
        }

    }

}
}

// d
