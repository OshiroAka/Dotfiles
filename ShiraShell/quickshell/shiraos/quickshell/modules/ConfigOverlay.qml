import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "shiraos-config-overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Padrão IslandExpanded: emptyMask quando fechado
    Region { id: emptyMask }
    mask: AppState.configOpen ? null : emptyMask

    property var  availFonts: []
    property var  openList:   []

    function aC() { return AppState.accentColor  || Qt.rgba(0.29,0.62,1.0,1.0) }
    function rC() { return AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25) }
    function dC() { return AppState.accentDark   || Qt.rgba(0.05,0.05,0.09,0.92) }
    function gF() { return AppState.globalFont   || "DejaVu Sans" }
    function iF() { return AppState.iconFont     || "MesloLGS Nerd Font" }

    // Overlay escuro
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.5)
        opacity: AppState.configOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onPressed: AppState.configOpen = false }
    }

    // Painel
    Rectangle {
        id: panel
        anchors.top:   parent.top
        anchors.right: parent.right
        anchors.topMargin:   10
        anchors.rightMargin: 150
        width: 480
        height: Math.min(col.implicitHeight + hdr.height + 32, win.height - 60)
        radius: 16
        color: win.dC()
        border.color: win.rC(); border.width: 1; antialiasing: true; clip: true

        opacity: AppState.configOpen ? 1 : 0
        scale:   AppState.configOpen ? 1 : 0.92
        transformOrigin: Item.TopRight
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Header
        Rectangle {
            id: hdr
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 44; color: win.dC(); z: 2
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: win.rC() }
            Text {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                text: "Configurações"; font.family: win.gF(); font.pixelSize: 14; font.weight: Font.Bold
                color: Qt.rgba(1,1,1,0.9)
            }
            Rectangle {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                width: 24; height: 24; radius: 12
                color: xH.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.04)
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.5) }
                MouseArea { id: xH; anchors.fill: parent; hoverEnabled: true; onPressed: AppState.configOpen = false }
            }
        }

        Flickable {
            anchors { top: hdr.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            contentHeight: col.implicitHeight + 24; clip: true

            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 16; rightMargin: 16; topMargin: 14 }
                spacing: 14

                // Estilo da borda
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "ESTILO DA BORDA"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Row {
                        width: parent.width; spacing: 6
                        Repeater {
                            model: [{n:0,l:"Esquerda"},{n:1,l:"Baixo Centro"},{n:2,l:"Baixo Esq."},{n:3,l:"Full"}]
                            delegate: Rectangle {
                                property bool act: AppState.dockStyle === modelData.n
                                width: (parent.width-18)/4; height: 60; radius: 10
                                color: act?Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.15):Qt.rgba(1,1,1,0.04)
                                border.color: act?win.aC():win.rC(); border.width: act?2:1; antialiasing: true
                                Behavior on color        { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Item {
                                    anchors { fill: parent; margins: 8; bottomMargin: 18 }
                                    Rectangle {
                                        anchors.fill: parent; radius: 4; color: Qt.rgba(1,1,1,0.05)
                                        Rectangle {
                                            visible: modelData.n===0
                                            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 3 }
                                            width: 4; height: parent.height*0.65; radius: 2; color: win.aC()
                                        }
                                        Rectangle {
                                            visible: modelData.n===1
                                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 3 }
                                            width: parent.width*0.6; height: 4; radius: 2; color: win.aC()
                                        }
                                        Rectangle {
                                            visible: modelData.n===2
                                            anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 3; leftMargin: 3 }
                                            width: parent.width*0.55; height: 4; radius: 2; color: win.aC()
                                        }
                                        Rectangle {
                                            visible: modelData.n===3
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: 3; margins: 3 }
                                            height: 4; radius: 2; color: win.aC()
                                        }
                                    }
                                }
                                Text {
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 6 }
                                    text: modelData.l; font.family: win.gF(); font.pixelSize: 9
                                    color: act ? win.aC() : Qt.rgba(1,1,1,0.4)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: { AppState.dockStyle = modelData.n; saveProc.running = false; saveProc.running = true }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                // Wallpaper
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "POSIÇÃO DO WALLPAPER"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Row {
                        width: parent.width; spacing: 6
                        Repeater {
                            model: [{n:0,l:"Lateral"},{n:1,l:"Centro"},{n:2,l:"Island"}]
                            delegate: Rectangle {
                                property bool act: AppState.wallpaperStyle === modelData.n
                                width: (parent.width-12)/3; height: 36; radius: 10
                                color: act?Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.15):Qt.rgba(1,1,1,0.04)
                                border.color: act?win.aC():win.rC(); border.width: act?2:1; antialiasing: true
                                Behavior on color        { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Text { anchors.centerIn: parent; text: modelData.l; font.family: win.gF(); font.pixelSize: 11; color: act?win.aC():Qt.rgba(1,1,1,0.5) }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: { AppState.wallpaperStyle = modelData.n; saveProc.running = false; saveProc.running = true }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                // Fonte
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "FONTE"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Text { text: "ShiraOS  Aa Bb  0123"; font.family: win.gF(); font.pixelSize: 13; color: win.aC() }
                    Rectangle {
                        width: parent.width; height: 100; radius: 10; color: Qt.rgba(1,1,1,0.03); clip: true
                        ListView {
                            id: fList
                            anchors { fill: parent; margins: 4 }
                            model: win.availFonts; clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            delegate: Rectangle {
                                id: fi; property bool act: AppState.globalFont === modelData
                                width: fList.width; height: 28; radius: 7
                                color: act?Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.13):fH.containsMouse?Qt.rgba(1,1,1,0.05):"transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text { text: fi.act?"✓":" "; font.pixelSize: 10; color: win.aC(); width: 12 }
                                    Text { text: modelData; font.family: modelData; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.85) }
                                }
                                MouseArea { id: fH; anchors.fill: parent; hoverEnabled: true; onPressed: { AppState.globalFont=modelData; saveProc.running=false; saveProc.running=true } }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: win.rC() }

                // Apps fixados
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "APPS FIXADOS"; font.family: win.gF(); font.pixelSize: 9; font.letterSpacing: 1.4; color: Qt.rgba(1,1,1,0.4) }
                    Column {
                        width: parent.width; spacing: 3
                        Repeater {
                            model: AppState.pinnedApps || []
                            delegate: Rectangle {
                                width: parent.width; height: 34; radius: 8; color: Qt.rgba(1,1,1,0.04)
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text { text: modelData.icon||""; font.family: win.iF(); font.pixelSize: 15; color: Qt.rgba(1,1,1,0.85) }
                                    Text { text: modelData.label||""; font.family: win.gF(); font.pixelSize: 11; color: Qt.rgba(1,1,1,0.85) }
                                    Text { text: modelData.cmd||""; font.family: win.gF(); font.pixelSize: 9; color: Qt.rgba(1,1,1,0.35) }
                                }
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    width: 22; height: 22; radius: 6
                                    color: rH.containsMouse?Qt.rgba(1,0.3,0.3,0.16):"transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: Qt.rgba(1,0.5,0.5,0.8) }
                                    MouseArea { id: rH; anchors.fill: parent; hoverEnabled: true; onPressed: { var a=(AppState.pinnedApps||[]).slice(); a.splice(index,1); AppState.pinnedApps=a; saveProc.running=false; saveProc.running=true } }
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
                                height: 24; radius: 6; width: cT.implicitWidth+20
                                color: pinned?Qt.rgba(win.aC().r,win.aC().g,win.aC().b,0.15):Qt.rgba(1,1,1,0.06)
                                border.color: pinned?win.aC():"transparent"; border.width: 1
                                Row { anchors.centerIn: parent; spacing: 4
                                    Text { text: chip.pinned?"✓":"+"; font.pixelSize: 9; color: chip.pinned?win.aC():Qt.rgba(1,1,1,0.4) }
                                    Text { id: cT; text: modelData; font.family: win.gF(); font.pixelSize: 9; color: Qt.rgba(1,1,1,0.85) }
                                }
                                MouseArea { anchors.fill: parent; onPressed: {
                                    if(!chip.pinned){
                                        var arr=(AppState.pinnedApps||[]).slice(),label=modelData
                                        var k={"kitty":{icon:"\uf120",cmd:"kitty"},"firefox":{icon:"\uf269",cmd:"firefox"},"code":{icon:"\ue70c",cmd:"code"},"spotify":{icon:"\uf1bc",cmd:"spotify"},"nautilus":{icon:"\uf07b",cmd:"nautilus"}}
                                        var ic="\uf096",cm=label.toLowerCase().replace(/ /g,"-")
                                        for(var x in k){if(label.toLowerCase().indexOf(x)>=0){ic=k[x].icon;cm=k[x].cmd;break}}
                                        arr.push({icon:ic,label:label,cmd:cm}); AppState.pinnedApps=arr; saveProc.running=false; saveProc.running=true
                                    }
                                } }
                            }
                        }
                        Text { visible: win.openList.length===0; text: "Nenhum app aberto"; font.family: win.gF(); font.pixelSize: 11; color: Qt.rgba(1,1,1,0.3) }
                    }
                }
                Item { width: 1; height: 6 }
            }
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
        command: ["python3","-c","import json,os\np='/home/oshiro/.config/quickshell/shiraos/dock_config.json'\nc=json.load(open(p)) if os.path.exists(p) else {}\nc['style']="+String(AppState.dockStyle||0)+"\nc['wallpaperStyle']="+String(AppState.wallpaperStyle||0)+"\nc['uiFont']="+JSON.stringify(String(AppState.globalFont||"DejaVu Sans"))+"\nc['pinned']="+JSON.stringify(AppState.pinnedApps||[])+"\njson.dump(c,open(p,'w'),indent=2,ensure_ascii=False)"]
        onExited: running=false
    }

    Timer {
        interval: 150; running: true; repeat: true
        property bool prev: false
        onTriggered: {
            var cur = AppState.configOpen || false
            if (cur && !prev) {
                appsProc.running = false; appsProc.running = true
                fontsProc.running = false; fontsProc.running = true
            }
            prev = cur
        }
    }
}
