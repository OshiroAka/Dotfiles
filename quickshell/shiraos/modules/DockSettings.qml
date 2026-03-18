import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ShiraOS

// PopupWindow: ancora ao LeftBorder e aparece acima da dock
// Padrão da documentação oficial do Quickshell
PopupWindow {
    id: win

    // Ancora ao LeftBorder (definido em shell.qml como id: leftBorder)
    anchor.window: leftBorder
    // Posição: centralizado horizontalmente, acima da dock
    anchor.rect.x: (anchor.window ? anchor.window.width / 2 - 250 : 0)
    anchor.rect.y: 0

    implicitWidth:  500
    implicitHeight: Math.min(flickable.contentHeight + topBar.height + 8, 700)

    visible: AppState.dockSettingsOpen || false

    color: "transparent"

    property var availFonts: []
    property var openList:   []

    function aC() { return AppState.accentColor  || Qt.rgba(0.29,0.62,1.0,1.0) }
    function rC() { return AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25) }
    function dC() { return AppState.accentDark   || Qt.rgba(0.05,0.05,0.09,0.97) }
    function gF() { return AppState.globalFont   || "DejaVu Sans" }
    function iF() { return AppState.iconFont     || "MesloLGS Nerd Font" }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: win.dC()
        border.color: win.rC()
        border.width: 1
        antialiasing: true
        clip: true

        Rectangle {
            id: topBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 48; color: win.dC(); z: 2
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: win.rC() }
            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 18; rightMargin: 12 }
                Text { text: "Dock"; font.family: win.gF(); font.pixelSize: 15; font.weight: Font.Bold; color: Qt.rgba(1,1,1,0.9); width: parent.width - 32 }
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: xM.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.05)
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.5) }
                    MouseArea { id: xM; anchors.fill: parent; hoverEnabled: true; onClicked: AppState.dockSettingsOpen = false }
                }
            }
        }

        Flickable {
            id: flickable
            anchors { top: topBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            contentHeight: body.implicitHeight + 24; clip: true

            Column {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 18; rightMargin: 18; topMargin: 14 }
                spacing: 18

                Column {
                    width: parent.width; spacing: 8
                    Text { text: "ESTILO"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Row {
                        width: parent.width; spacing: 8
                        Repeater {
                            model: [{id:0,label:"Baixo Centro"},{id:1,label:"Esquerda"},{id:2,label:"Baixo Esq."},{id:3,label:"Full"}]
                            delegate: Rectangle {
                                id: sc; property int sid: modelData.id
                                property bool active: AppState.dockStyle === sid
                                width: (parent.width-24)/4; height: 72; radius: 11
                                color: active ? Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.15) : Qt.rgba(1,1,1,0.04)
                                border.color: active ? win.aC() : win.rC(); border.width: active?2:1; antialiasing: true
                                Behavior on color        { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Item {
                                    anchors { fill: parent; margins: 9; bottomMargin: 20 }
                                    Rectangle {
                                        anchors.fill: parent; radius: 5; color: Qt.rgba(1,1,1,0.05)
                                        Rectangle {
                                            visible: sc.sid === 0
                                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 3 }
                                            width: parent.width*0.6; height: 4; radius: 2; color: win.aC(); opacity: 0.9
                                        }
                                        Rectangle {
                                            visible: sc.sid === 1
                                            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 3 }
                                            width: 4; height: parent.height*0.65; radius: 2; color: win.aC(); opacity: 0.9
                                        }
                                        Rectangle {
                                            visible: sc.sid === 2
                                            anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 3; leftMargin: 3 }
                                            width: parent.width*0.55; height: 4; radius: 2; color: win.aC(); opacity: 0.9
                                        }
                                        Rectangle {
                                            visible: sc.sid === 3
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: 3; margins: 3 }
                                            height: 4; radius: 2; color: win.aC(); opacity: 0.9
                                        }
                                    }
                                }
                                Text {
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 6 }
                                    text: modelData.label; font.family: win.gF(); font.pixelSize: 9
                                    color: active ? win.aC() : Qt.rgba(1,1,1,0.4)
                                }
                                MouseArea { anchors.fill: parent; onClicked: { AppState.dockStyle = sc.sid; saveProc.running = true } }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                Column {
                    width: parent.width; spacing: 8
                    Text { text: "FONTE"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Text { text: "ShiraOS  Aa Bb  0123"; font.family: win.gF(); font.pixelSize: 14; color: win.aC() }
                    Rectangle {
                        width: parent.width; height: 130; radius: 10; color: Qt.rgba(1,1,1,0.03); clip: true
                        ListView {
                            id: fList
                            anchors { fill: parent; margins: 4 }
                            model: win.availFonts; clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            delegate: Rectangle {
                                id: fi; property bool active: AppState.globalFont === modelData
                                width: fList.width; height: 28; radius: 7
                                color: active ? Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.13) : fHov.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text { text: fi.active?"✓":" "; font.pixelSize: 10; color: win.aC(); width: 12 }
                                    Text { text: modelData; font.family: modelData; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.85) }
                                }
                                MouseArea { id: fHov; anchors.fill: parent; hoverEnabled: true; onClicked: { AppState.globalFont = modelData; saveProc.running = true } }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                Column {
                    width: parent.width; spacing: 8
                    Text { text: "APPS FIXADOS"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Column {
                        width: parent.width; spacing: 3
                        Repeater {
                            model: AppState.pinnedApps || []
                            delegate: Rectangle {
                                width: parent.width; height: 36; radius: 9; color: Qt.rgba(1,1,1,0.04)
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 10
                                    Text { text: modelData.icon||""; font.family: win.iF(); font.pixelSize: 16; color: Qt.rgba(1,1,1,0.85) }
                                    Text { text: modelData.label||""; font.family: win.gF(); font.pixelSize: 11; color: Qt.rgba(1,1,1,0.85) }
                                    Text { text: modelData.cmd||""; font.family: win.gF(); font.pixelSize: 9; color: Qt.rgba(1,1,1,0.35) }
                                }
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    width: 24; height: 24; radius: 7
                                    color: rmH.containsMouse ? Qt.rgba(1,0.3,0.3,0.16) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: Qt.rgba(1,0.5,0.5,0.8) }
                                    MouseArea {
                                        id: rmH; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { var a=(AppState.pinnedApps||[]).slice(); a.splice(index,1); AppState.pinnedApps=a; saveProc.running=true }
                                    }
                                }
                            }
                        }
                        Text { visible: (AppState.pinnedApps||[]).length===0; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Nenhum app fixado"; font.family: win.gF(); font.pixelSize: 11; color: Qt.rgba(1,1,1,0.3) }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                Column {
                    width: parent.width; spacing: 8
                    Text { text: "FIXAR APP ABERTO"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Flow {
                        width: parent.width; spacing: 5
                        Repeater {
                            model: win.openList
                            delegate: Rectangle {
                                id: chip
                                property bool pinned: { var a=AppState.pinnedApps||[]; for(var i=0;i<a.length;i++) if(a[i].label===modelData) return true; return false }
                                height: 26; radius: 7; width: cTxt.implicitWidth+22
                                color: pinned?Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.15):Qt.rgba(1,1,1,0.06)
                                border.color: pinned?win.aC():"transparent"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row { anchors.centerIn: parent; spacing: 4
                                    Text { text: chip.pinned?"✓":"+"; font.pixelSize: 9; color: chip.pinned?win.aC():Qt.rgba(1,1,1,0.4) }
                                    Text { id: cTxt; text: modelData; font.family: win.gF(); font.pixelSize: 9; color: Qt.rgba(1,1,1,0.85) }
                                }
                                MouseArea { anchors.fill: parent; onClicked: {
                                    if(!chip.pinned){
                                        var arr=(AppState.pinnedApps||[]).slice(), label=modelData
                                        var known={"kitty":{icon:"",cmd:"kitty"},"firefox":{icon:"",cmd:"firefox"},"code":{icon:"",cmd:"code"},"spotify":{icon:"",cmd:"spotify"},"nautilus":{icon:"",cmd:"nautilus"},"telegram":{icon:"",cmd:"telegram-desktop"},"discord":{icon:"",cmd:"discord"}}
                                        var icon="",cmd=label.toLowerCase().replace(/ /g,"-")
                                        for(var k in known){if(label.toLowerCase().indexOf(k)>=0){icon=known[k].icon;cmd=known[k].cmd;break}}
                                        arr.push({icon:icon,label:label,cmd:cmd}); AppState.pinnedApps=arr; saveProc.running=true
                                    }
                                }}
                            }
                        }
                        Text { visible: win.openList.length===0; text: "Nenhum app aberto"; font.family: win.gF(); font.pixelSize: 11; color: Qt.rgba(1,1,1,0.3) }
                    }
                }
                Item { width: 1; height: 6 }
            }
        }
    }

    Process { id: appsProc; running: false
        command: ["sh","-c","hyprctl clients -j 2>/dev/null | python3 -c \"import sys,json;c=json.load(sys.stdin);[print(x['title']) for x in c if x.get('title','').strip()]\""]
        stdout: SplitParser { onRead: function(d){ if(d.trim()){ var a=win.openList.slice();a.push(d.trim());win.openList=a } } }
        onStarted: win.openList=[]; onExited: running=false
    }
    Process { id: fontsProc; running: false
        command: ["python3","-c",
            "import json,os\n" +
            "p='/home/oshiro/.config/quickshell/shiraos/dock_config.json'\n" +
            "c=json.load(open(p)) if os.path.exists(p) else {}\n" +
            "[print(f) for f in c.get('availableFonts',[])]"
        ]
        stdout: SplitParser { onRead: function(d){ if(d.trim()){ var a=win.availFonts.slice();a.push(d.trim());win.availFonts=a } } }
        onStarted: win.availFonts=[]; onExited: running=false
    }
    Process { id: saveProc; running: false
        command: ["python3","-c",
            "import json,os\n" +
            "p='/home/oshiro/.config/quickshell/shiraos/dock_config.json'\n" +
            "c=json.load(open(p)) if os.path.exists(p) else {}\n" +
            "c['style']=" + String(AppState.dockStyle||0) + "\n" +
            "c['uiFont']=" + JSON.stringify(String(AppState.globalFont||"DejaVu Sans")) + "\n" +
            "c['pinned']=" + JSON.stringify(AppState.pinnedApps||[]) + "\n" +
            "json.dump(c,open(p,'w'),indent=2,ensure_ascii=False)"
        ]
        onExited: running=false
    }

    onVisibleChanged: {
        if (visible) {
            appsProc.running = false; appsProc.running = true
            fontsProc.running = false; fontsProc.running = true
        }
    }
}
