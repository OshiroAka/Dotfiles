import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "shiraos-config"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.top:   true
    anchors.right: true
    margins.right: 0
    margins.top:   0
    implicitWidth:  screen ? screen.width : 1920
    implicitHeight: panelOpen ? 10 + pillH + panelRect.height + 8 : 10 + pillH
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    property bool panelOpen: false
    property int  pillH: 36
    property int  pillW: 44
    property var  availFonts: []
    property var  openList:   []

    // Sem mask — janela pequena no canto não precisa restringir input
    mask: null

    property color cAccent: AppState.accentColor  || Qt.rgba(0.29,0.62,1.0,1.0)
    property color cBg:     AppState.accentPill   || Qt.rgba(0.06,0.06,0.12,0.30)
    property color cRim:    AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25)
    property color cDark:   AppState.accentDark   || Qt.rgba(0.06,0.06,0.10,0.75)
    property color cText:   Qt.rgba(1,1,1,0.90)
    property color cDim:    Qt.rgba(1,1,1,0.45)
    function gF() { return AppState.globalFont || "DejaVu Sans" }
    function iF() { return AppState.iconFont   || "MesloLGS Nerd Font" }

    // ── Pill ⚙ ───────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 150
        width: 44; height: win.pillH; radius: win.pillH / 2
        color: win.cBg; border.color: win.cRim; border.width: 1; antialiasing: true
        Behavior on color        { ColorAnimation { duration: 800 } }
        Behavior on border.color { ColorAnimation { duration: 800 } }

        Text {
            anchors.centerIn: parent
            font.family: win.iF(); font.pixelSize: 16; text: "\uf013"
            color: win.panelOpen ? win.cAccent : win.cDim
            Behavior on color { ColorAnimation { duration: 150 } }
            rotation: win.panelOpen ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                win.panelOpen = !win.panelOpen
                if (win.panelOpen) {
                    appsProc.running = false; appsProc.running = true
                    fontsProc.running = false; fontsProc.running = true
                }
            }
        }
    }

    // ── Painel dropdown ───────────────────────────────────────
    Rectangle {
        id: panelRect
        anchors.top: pill.bottom
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.rightMargin: 10
        width: 580
        height: panelContent.implicitHeight + 24
        radius: 16
        color: Qt.rgba(win.cDark.r, win.cDark.g, win.cDark.b, 0.65); border.color: win.cRim; border.width: 1; antialiasing: true; clip: true

        opacity: win.panelOpen ? 1 : 0
        scale:   win.panelOpen ? 1 : 0.92
        transformOrigin: Item.TopRight
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }

        Column {
            id: panelContent
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 16; rightMargin: 16; topMargin: 16 }
            spacing: 16

            // Estilos
            Column {
                width: parent.width; spacing: 8
                Text { text: "ESTILO DA DOCK"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: win.cDim }
                Row {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [{id:0,label:"Baixo Centro"},{id:1,label:"Esquerda"},{id:2,label:"Baixo Esq."},{id:3,label:"Full"}]
                        delegate: Rectangle {
                            id: sc; property int sid: modelData.id; property bool active: AppState.dockStyle===sid
                            width: (parent.width-18)/4; height: 68; radius: 10
                            color: active?Qt.rgba(win.cAccent.r,win.cAccent.g,win.cAccent.b,0.15):Qt.rgba(1,1,1,0.04)
                            border.color: active?win.cAccent:win.cRim; border.width: active?2:1; antialiasing: true
                            Behavior on color        { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Item {
                                anchors { fill: parent; margins: 8; bottomMargin: 20 }
                                Rectangle { anchors.fill: parent; radius: 5; color: Qt.rgba(1,1,1,0.05)
                                    Rectangle {
                                        visible: sc.sid===0
                                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 3 }
                                        width: parent.width*0.6; height: 4; radius: 2; color: win.cAccent; opacity: 0.9
                                    }
                                    Rectangle {
                                        visible: sc.sid===1
                                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 3 }
                                        width: 4; height: parent.height*0.65; radius: 2; color: win.cAccent; opacity: 0.9
                                    }
                                    Rectangle {
                                        visible: sc.sid===2
                                        anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 3; leftMargin: 3 }
                                        width: parent.width*0.55; height: 4; radius: 2; color: win.cAccent; opacity: 0.9
                                    }
                                    Rectangle {
                                        visible: sc.sid===3
                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: 3; margins: 3 }
                                        height: 4; radius: 2; color: win.cAccent; opacity: 0.9
                                    }
                                }
                            }
                            Text {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 6 }
                                text: modelData.label; font.family: win.gF(); font.pixelSize: 9
                                color: active ? win.cAccent : win.cDim
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    AppState.dockStyle = sc.sid
                                    saveProc.running = false
                                    saveProc.running = true
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: win.cRim }

            // Fonte
            Column {
                width: parent.width; spacing: 8
                Text { text: "FONTE"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: win.cDim }
                Text { text: "ShiraOS  Aa Bb  0123"; font.family: win.gF(); font.pixelSize: 13; color: win.cAccent }
                Rectangle {
                    width: parent.width; height: 120; radius: 10; color: Qt.rgba(1,1,1,0.03); clip: true
                    ListView {
                        id: fList; anchors { fill: parent; margins: 4 }
                        model: win.availFonts; clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Rectangle {
                            id: fi; property bool active: AppState.globalFont===modelData
                            width: fList.width; height: 28; radius: 7
                            color: active?Qt.rgba(win.cAccent.r,win.cAccent.g,win.cAccent.b,0.13):fHov.containsMouse?Qt.rgba(1,1,1,0.05):"transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Row {
                                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 8
                                Text { text: fi.active?"✓":" "; font.pixelSize: 10; color: win.cAccent; width: 12 }
                                Text { text: modelData; font.family: modelData; font.pixelSize: 11; color: win.cText }
                            }
                            MouseArea { id: fHov; anchors.fill: parent; hoverEnabled: true; onClicked: { AppState.globalFont=modelData; saveProc.running=true } }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: win.cRim }

            // Apps fixados
            Column {
                width: parent.width; spacing: 8
                Text { text: "APPS FIXADOS"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: win.cDim }
                Column {
                    width: parent.width; spacing: 3
                    Repeater {
                        model: AppState.pinnedApps || []
                        delegate: Rectangle {
                            width: parent.width; height: 34; radius: 8; color: Qt.rgba(1,1,1,0.04)
                            Row {
                                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 8
                                Text { text: modelData.icon||""; font.family: win.iF(); font.pixelSize: 15; color: win.cText }
                                Text { text: modelData.label||""; font.family: win.gF(); font.pixelSize: 11; color: win.cText }
                                Text { text: modelData.cmd||""; font.family: win.gF(); font.pixelSize: 9; color: win.cDim }
                            }
                            Rectangle {
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                width: 22; height: 22; radius: 6
                                color: rmH.containsMouse?Qt.rgba(1,0.3,0.3,0.16):"transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: Qt.rgba(1,0.5,0.5,0.8) }
                                MouseArea { id: rmH; anchors.fill: parent; hoverEnabled: true; onClicked: { var a=(AppState.pinnedApps||[]).slice(); a.splice(index,1); AppState.pinnedApps=a; saveProc.running=true } }
                            }
                        }
                    }
                    Text { visible:(AppState.pinnedApps||[]).length===0; width:parent.width; horizontalAlignment:Text.AlignHCenter; text:"Nenhum app fixado"; font.family:win.gF(); font.pixelSize:11; color:win.cDim }
                }
            }

            Rectangle { width: parent.width; height: 1; color: win.cRim }

            Column {
                width: parent.width; spacing: 8
                Text { text: "FIXAR APP ABERTO"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: win.cDim }
                Flow {
                    width: parent.width; spacing: 5
                    Repeater {
                        model: win.openList
                        delegate: Rectangle {
                            id: chip
                            property bool pinned: { var a=AppState.pinnedApps||[]; for(var i=0;i<a.length;i++) if(a[i].label===modelData) return true; return false }
                            height: 24; radius: 6; width: cTxt.implicitWidth+20
                            color: pinned?Qt.rgba(win.cAccent.r,win.cAccent.g,win.cAccent.b,0.15):Qt.rgba(1,1,1,0.06)
                            border.color: pinned?win.cAccent:"transparent"; border.width:1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Row { anchors.centerIn: parent; spacing: 4
                                Text { text: chip.pinned?"✓":"+"; font.pixelSize: 9; color: chip.pinned?win.cAccent:win.cDim }
                                Text { id: cTxt; text: modelData; font.family: win.gF(); font.pixelSize: 9; color: win.cText }
                            }
                            MouseArea { anchors.fill: parent; onClicked: {
                                if(!chip.pinned){
                                    var arr=(AppState.pinnedApps||[]).slice(), label=modelData
                                    var known={"kitty":{icon:"\uf120",cmd:"kitty"},"firefox":{icon:"\uf269",cmd:"firefox"},"code":{icon:"\ue70c",cmd:"code"},"spotify":{icon:"\uf1bc",cmd:"spotify"},"nautilus":{icon:"\uf07b",cmd:"nautilus"}}
                                    var icon="\uf096",cmd=label.toLowerCase().replace(/ /g,"-")
                                    for(var k in known){if(label.toLowerCase().indexOf(k)>=0){icon=known[k].icon;cmd=known[k].cmd;break}}
                                    arr.push({icon:icon,label:label,cmd:cmd}); AppState.pinnedApps=arr; saveProc.running=true
                                }
                            } }
                        }
                    }
                    Text { visible:win.openList.length===0; text:"Nenhum app aberto"; font.family:win.gF(); font.pixelSize:11; color:win.cDim }
                }
            }
            Item { width: 1; height: 4 }
        }
    }

    Process { id: appsProc; running: false; command: ["sh","-c","hyprctl clients -j 2>/dev/null | python3 -c \"import sys,json;c=json.load(sys.stdin);[print(x['title']) for x in c if x.get('title','').strip()]\""]
        stdout: SplitParser { onRead: function(d){ if(d.trim()){ var a=win.openList.slice();a.push(d.trim());win.openList=a } } }
        onStarted: win.openList=[]; onExited: running=false
    }
    Process { id: fontsProc; running: false; command: ["python3","-c","import json,os\np='/home/oshiro/.config/quickshell/shiraos/dock_config.json'\nc=json.load(open(p)) if os.path.exists(p) else {}\n[print(f) for f in c.get('availableFonts',[])]"]
        stdout: SplitParser { onRead: function(d){ if(d.trim()){ var a=win.availFonts.slice();a.push(d.trim());win.availFonts=a } } }
        onStarted: win.availFonts=[]; onExited: running=false
    }
    Process { id: saveProc; running: false
        command: ["python3","-c","import json,os\np='/home/oshiro/.config/quickshell/shiraos/dock_config.json'\nc=json.load(open(p)) if os.path.exists(p) else {}\nc['style']="+String(AppState.dockStyle||0)+"\nc['uiFont']="+JSON.stringify(String(AppState.globalFont||"DejaVu Sans"))+"\nc['pinned']="+JSON.stringify(AppState.pinnedApps||[])+"\njson.dump(c,open(p,'w'),indent=2,ensure_ascii=False)"]
        onExited: running=false
    }
}
