import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.namespace:     "shiraos-border"
    WlrLayershell.exclusiveZone: 60
    anchors { top: true; bottom: true; left: true }
    implicitWidth: 60
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    function pillColor()  { return AppState.accentPill   || Qt.rgba(0.06,0.06,0.09,0.40) }
    function borderColor(){ return AppState.accentBorder || Qt.rgba(0.3,0.3,0.6,0.25) }
    function accentCol()  { return AppState.accentColor  || Qt.rgba(0.55,0.55,1.0,1.0) }

    property string focusedApp: ""

    property var openApps: []

    // ── Janela focada ─────────────────────────────────────────────────────
    Process {
        id: focusProc
        command: ["/bin/bash","-c",
            "hyprctl activewindow -j 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('class',''))\" 2>/dev/null"]
        running: false
        stdout: SplitParser { onRead: function(l){ win.focusedApp = l.trim() } }
    }
    Timer { interval:1500; running:true; repeat:true; triggeredOnStart:true
            onTriggered:{ focusProc.running=false; focusProc.running=true } }

    // ── Apps abertos ──────────────────────────────────────────────────────
    Process {
        id: appsProc
        command: ["/bin/bash","-c", [
            "hyprctl clients -j 2>/dev/null | python3 -c \"",
            "import json,sys,os,glob as g",
            ";clients=json.load(sys.stdin)",
            ";seen=set()",
            ";dirs=['/usr/share/icons/hicolor/48x48/apps','/usr/share/icons/hicolor/32x32/apps','/usr/share/icons/hicolor/scalable/apps','/usr/share/pixmaps']+g.glob('/usr/share/icons/*/48x48/apps')+g.glob('/usr/share/icons/*/scalable/apps')+[os.path.expanduser('~/.local/share/icons/hicolor/48x48/apps')]",
            ";find_icon=lambda n:[next((os.path.join(d,n+e) for d in dirs for e in ['.png','.svg','.xpm'] if os.path.exists(os.path.join(d,n+e))),'')]",
            ";[print('A:'+c['class']+'|'+c['title'][:28].replace('|','')+'|'+c['address']+'|'+(find_icon(c['class'].lower())[0] or find_icon(c['class'])[0])) for c in clients if c.get('class') and c['class'] not in seen and not seen.add(c['class'])]",
            "\" 2>/dev/null"
        ].join("")]
        running: false
        property var tempApps: []
        stdout: SplitParser {
            onRead: function(l){
                if(l.startsWith("A:")){
                    var p=l.slice(2).split("|")
                    var arr=appsProc.tempApps.slice()
                    arr.push({cls:p[0]||"",title:p[1]||"",addr:p[2]||"",icon:p[3]||""})
                    appsProc.tempApps=arr
                }
            }
        }
        onRunningChanged: {
            if(running) appsProc.tempApps=[]
        }
        onExited: {
            var a=JSON.stringify(appsProc.tempApps)
            var b=JSON.stringify(win.openApps)
            if(a!==b) win.openApps=appsProc.tempApps
        }
    }
    Timer { interval:4000; running:true; repeat:true; triggeredOnStart:true
            onTriggered:{ appsProc.running=false; appsProc.running=true } }

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill:parent; topMargin:8; bottomMargin:8; leftMargin:6; rightMargin:6 }
        radius:12; color:win.pillColor()
        border.color:win.borderColor(); border.width:1
        Behavior on color         { ColorAnimation{duration:600} }
        Behavior on border.color  { ColorAnimation{duration:600} }
    }

    // ── Ícones ────────────────────────────────────────────────────────────
    Column {
        id: sideCol
        anchors { top:parent.top; bottom:parent.bottom; left:parent.left; right:parent.right
                  topMargin:14; bottomMargin:14 }
        spacing: 4

        // Janela focada
        Item {
            id: focusedItem
            width:parent.width; height:46
            Column {
                anchors.centerIn:parent; spacing:3
                Rectangle {
                    anchors.horizontalCenter:parent.horizontalCenter
                    width:36; height:36; radius:10
                    color:Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.15)
                    border.color:Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.4)
                    border.width:1
                    Text { anchors.centerIn:parent
                           text:win.focusedApp?win.focusedApp.charAt(0).toUpperCase():"·"
                           color:win.accentCol(); font.pixelSize:16; font.bold:true }
                }
                Text { anchors.horizontalCenter:parent.horizontalCenter
                       text:"focus"; color:Qt.rgba(1,1,1,0.2); font.pixelSize:7 }
            }
        }

        Rectangle { width:parent.width-16; height:1
                    anchors.horizontalCenter:parent.horizontalCenter
                    color:Qt.rgba(1,1,1,0.07) }

        // Apps abertos
        Item {
            id: appsIconArea
            width:parent.width
            height:Math.min(win.openApps.length,7)*42+4
            Column {
                anchors { top:parent.top; topMargin:4; horizontalCenter:parent.horizontalCenter }
                spacing:4
                Repeater {
                    model:Math.min(win.openApps.length,7)
                    delegate: Item {
                        width:44; height:36
                        property var    app:     win.openApps[index]||{}
                        property string cls:     app.cls||""
                        property bool   focused: cls.toLowerCase()===win.focusedApp.toLowerCase()
                        Rectangle {
                            anchors.fill:parent; radius:9
                            color:focused?Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.2):Qt.rgba(1,1,1,0.05)
                            border.color:focused?win.accentCol():"transparent"; border.width:1
                            Behavior on color{ColorAnimation{duration:150}}
                        }
                        Text { anchors.centerIn:parent; text:cls.charAt(0).toUpperCase()
                               color:focused?win.accentCol():Qt.rgba(1,1,1,0.55)
                               font.pixelSize:15; font.bold:focused }
                        Rectangle {
                            anchors.bottom:parent.bottom; anchors.bottomMargin:1
                            anchors.horizontalCenter:parent.horizontalCenter
                            width:focused?14:4; height:3; radius:2; color:win.accentCol()
                            opacity:focused?1.0:0.3
                            Behavior on width{NumberAnimation{duration:180;easing.type:Easing.OutExpo}}
                        }
                    }
                }
            }
            MouseArea {
                anchors.fill:parent; hoverEnabled:true
                onEntered: {
                    var cy = appsIconArea.mapToItem(null, 0, appsIconArea.height/2).y
                    AppState.borderOverlayY = cy
                    AppState.borderOverlay  = "apps"
                }
                onExited: Qt.callLater(function(){ /* overlay takes over */ })
            }
        }

        Rectangle { width:parent.width-16; height:1
                    anchors.horizontalCenter:parent.horizontalCenter
                    color:Qt.rgba(1,1,1,0.07) }
        Item { width:1; height:4 }

        // Spotify
        Item {
            id: spotifyIconArea; width:parent.width; height:44
            Rectangle {
                anchors.centerIn:parent; width:36; height:36; radius:9
                color:spotifyMa.containsMouse?Qt.rgba(0.1,0.75,0.3,0.2):Qt.rgba(1,1,1,0.05)
                Behavior on color{ColorAnimation{duration:120}}
                Image {
                    anchors{fill:parent;margins:6}
                    source:"file:///usr/share/icons/hicolor/scalable/apps/spotify.svg"
                    fillMode:Image.PreserveAspectFit; smooth:true
                    visible: status===Image.Ready
                }
                Text {
                    anchors.centerIn:parent
                    visible: parent.children[0].status!==Image.Ready
                    text:"♫"; font.pixelSize:16
                    color:spotifyMa.containsMouse?"#1DB954":Qt.rgba(1,1,1,0.5)
                }
            }
            MouseArea { id:spotifyMa; anchors.fill:parent; hoverEnabled:true
                        onClicked:Qt.createQmlObject('import Quickshell.Io;Process{command:["/bin/bash","-c","spotify &"];running:true}',win) }
        }

        // Discord
        Item {
            id: discordIconArea; width:parent.width; height:44
            Rectangle {
                anchors.centerIn:parent; width:36; height:36; radius:9
                color:discordMa.containsMouse?Qt.rgba(0.35,0.4,0.9,0.2):Qt.rgba(1,1,1,0.05)
                Behavior on color{ColorAnimation{duration:120}}
                Image {
                    anchors{fill:parent;margins:6}
                    source:"file:///usr/share/icons/hicolor/scalable/apps/discord.svg"
                    fillMode:Image.PreserveAspectFit; smooth:true
                    visible: status===Image.Ready
                }
                Text {
                    anchors.centerIn:parent
                    visible: parent.children[0].status!==Image.Ready
                    text:"D"; font.pixelSize:15; font.bold:true
                    color:discordMa.containsMouse?"#7289DA":Qt.rgba(1,1,1,0.5)
                }
            }
            MouseArea { id:discordMa; anchors.fill:parent; hoverEnabled:true
                        onClicked:Qt.createQmlObject('import Quickshell.Io;Process{command:["/bin/bash","-c","discord &"];running:true}',win) }
        }

        Rectangle { width:parent.width-16; height:1
                    anchors.horizontalCenter:parent.horizontalCenter
                    color:Qt.rgba(1,1,1,0.07) }
        Item { width:1; height:4 }

        // Configurações (placeholder)
        Item {
            id: settingsIconArea; width:parent.width; height:44
            Rectangle {
                anchors.centerIn:parent; width:36; height:36; radius:9
                color:settingsMa.containsMouse?Qt.rgba(win.accentCol().r,win.accentCol().g,win.accentCol().b,0.15):Qt.rgba(1,1,1,0.05)
                Behavior on color{ColorAnimation{duration:120}}
                Text { anchors.centerIn:parent; text:"⚙"; font.pixelSize:18
                       color:settingsMa.containsMouse?win.accentCol():Qt.rgba(1,1,1,0.35)
                       rotation: settingsMa.containsMouse ? 45 : 0
                       Behavior on rotation{NumberAnimation{duration:300;easing.type:Easing.OutBack}} }
            }
            MouseArea { id:settingsMa; anchors.fill:parent; hoverEnabled:true }
        }

        // Power
        Item {
            id: powerIconArea; width:parent.width; height:44
            Rectangle {
                anchors.centerIn:parent; width:36; height:36; radius:9
                color:powerMa.containsMouse?Qt.rgba(1,0.2,0.2,0.2):Qt.rgba(1,1,1,0.05)
                Behavior on color{ColorAnimation{duration:120}}
                Text { anchors.centerIn:parent; text:"⏻"; font.pixelSize:18
                       color:powerMa.containsMouse?"#FF4444":Qt.rgba(1,1,1,0.45) }
            }
            MouseArea {
                id:powerMa; anchors.fill:parent; hoverEnabled:true
                onEntered: {
                    var cy = powerIconArea.mapToItem(null, 0, powerIconArea.height/2).y
                    AppState.borderOverlayY = cy
                    AppState.borderOverlay  = "power"
                }
                onExited: Qt.callLater(function(){ /* overlay takes over */ })
            }
        }
        Item { width:1; height:4 }
    }
}
