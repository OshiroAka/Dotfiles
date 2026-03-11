import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {
    id: win

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.namespace:     "shiraos-border"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true }
    implicitWidth: 262
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Mask correta: so pill + area popup (262px) recebe input
    property var inputMask: Region {
        Region { item: pill }
    }
    mask: inputMask



    // Estado
    property int    volumeLevel:     50
    property var    openApps:        []
    property string focusedApp:      ""
    property bool   isMaximized:     false
    property string musicStatus:     ""

    // Cores — fallback seguro, atualiza via Timer
    property color cAccent: Qt.rgba(0.29, 0.62, 1.0,  1.0)
    property color cBg:     Qt.rgba(0.06, 0.06, 0.12, 0.30)
    property color cRim:    Qt.rgba(0.30, 0.30, 0.60, 0.25)
    property color cText:   Qt.rgba(1.0,  1.0,  1.0,  0.90)
    property color cDim:    Qt.rgba(1.0,  1.0,  1.0,  0.45)

    // Copia as cores do AppState (definidas pelo WallpaperPanel)
    // Usa o mesmo padrao do WallpaperPanel: gc1 como base
    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var pill   = AppState.accentPill
            var border = AppState.accentBorder
            var accent = AppState.accentColor
            if (pill   && pill.a   > 0) win.cBg     = pill
            if (border && border.a > 0) win.cRim    = border
            if (accent && accent.a > 0) win.cAccent = accent
        }
    }

    // ── PILL ───────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors {
            top: parent.top; bottom: parent.bottom; left: parent.left
            topMargin: 10; bottomMargin: 10; leftMargin: 8
        }
        width: 44; radius: 22
        color: win.cBg
        border.color: win.cRim
        border.width: 1
        antialiasing: true
        opacity: win.isMaximized ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Behavior on color   { ColorAnimation  { duration: 800 } }
        Behavior on border.color { ColorAnimation { duration: 800 } }

        // Relógio
        Item {
            id: clockItem
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 16 }
            width: 40; height: 42
            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(new Date(), "HH")
                font.pixelSize: 15; font.weight: Font.Bold; color: win.cText
            }
            Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH") }
        }

        Rectangle {
            id: sep1
            anchors { top: clockItem.bottom; horizontalCenter: parent.horizontalCenter; topMargin: 4 }
            width: 24; height: 1; color: win.cRim
        }

        // Botão power no fundo
        Column {
            id: sysCol
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
            spacing: 0

            Rectangle {
                width: 24; height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: win.cRim
            }

            Item {
                id: powerArea
                width: 44; height: 44
                anchors.horizontalCenter: parent.horizontalCenter
                property bool popOpen: false

                Rectangle {
                    anchors { fill: parent; margins: 2 }
                    radius: 10
                    color: powerArea.popOpen ? Qt.rgba(0.9, 0.2, 0.2, 0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "\u23FB"; font.pixelSize: 22
                    color: powerArea.popOpen ? Qt.rgba(1, 0.45, 0.45, 1) : win.cDim
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { powerCloseT.stop(); powerArea.popOpen = true }
                    onExited:  powerCloseT.restart()
                }
                Timer { id: powerCloseT; interval: 350; onTriggered: powerArea.popOpen = false }

                Rectangle {
                    id: powerPop
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -8
                    x: parent.width + 6
                    width: 160; height: pwCol.implicitHeight + 16
                    radius: 14; color: win.cBg
                    border.color: win.cRim; border.width: 1; antialiasing: true
                    transformOrigin: Item.Left
                    scale: powerArea.popOpen ? 1.0 : 0.78
                    opacity: powerArea.popOpen ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Column {
                        id: pwCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 2

                        Text {
                            text: "SISTEMA"
                            font.pixelSize: 8; font.letterSpacing: 1.0; font.weight: Font.Medium
                            color: win.cDim
                            height: 20; verticalAlignment: Text.AlignBottom
                        }

                        Repeater {
                            model: [
                                { label: "Bloquear",  icon: "\uD83D\uDD12", cmd: ["loginctl", "lock-session"] },
                                { label: "Suspender", icon: "\u23FE",        cmd: ["systemctl", "suspend"]    },
                                { label: "Reiniciar", icon: "\u21BA",        cmd: ["systemctl", "reboot"]     },
                                { label: "Desligar",  icon: "\u23FB",        cmd: ["systemctl", "poweroff"]   }
                            ]
                            delegate: Item {
                                id: pwRow; width: parent.width; height: 30
                                property bool hov: false
                                Rectangle {
                                    anchors.fill: parent; radius: 8
                                    color: pwRow.hov ? Qt.rgba(0.9, 0.2, 0.2, 0.12) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 10
                                    Text { text: modelData.icon; font.pixelSize: 13; color: win.cDim }
                                    Text { text: modelData.label; font.pixelSize: 12; color: win.cText }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: { pwRow.hov = true; powerCloseT.stop() }
                                    onExited:  { pwRow.hov = false; powerCloseT.restart() }
                                    onClicked: { pwProc.command = modelData.cmd; pwProc.running = true }
                                }
                                Process { id: pwProc; running: false; command: []; onExited: running = false }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: powerCloseT.stop()
                        onExited:  powerCloseT.restart()
                    }
                }
            }
        }

        // Meio: apps + volume
        Column {
            id: midCol
            anchors {
                top: sep1.bottom; bottom: sysCol.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 6; bottomMargin: 6
            }
            spacing: 4

            Repeater {
                model: win.openApps.slice(0, 6)
                delegate: Item {
                    id: appArea; width: 44; height: 42
                    anchors.horizontalCenter: parent.horizontalCenter
                    property bool popOpen: false
                    property bool isActive: modelData === win.focusedApp

                    Rectangle {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 2 }
                        width: 3; radius: 2; color: win.cAccent
                        height: appArea.isActive ? 20 : (appArea.popOpen ? 12 : 5)
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                    Rectangle {
                        anchors { fill: parent; leftMargin: 6; margins: 2 }
                        radius: 10
                        color: appArea.popOpen ? Qt.rgba(1,1,1,0.10) : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        anchors { centerIn: parent; horizontalCenterOffset: 3 }
                        text: modelData.charAt(0).toUpperCase()
                        font.pixelSize: 19; font.weight: Font.Medium
                        color: appArea.isActive ? win.cAccent : (appArea.popOpen ? win.cText : win.cDim)
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: { appCloseT.stop(); appArea.popOpen = true }
                        onExited:  appCloseT.restart()
                        onClicked: { appFocProc.title = modelData; appFocProc.running = true }
                    }
                    Timer { id: appCloseT; interval: 350; onTriggered: appArea.popOpen = false }
                    Process {
                        id: appFocProc; running: false; property string title: ""
                        command: ["hyprctl", "dispatch", "focuswindow", "title:" + title]
                        onExited: running = false
                    }

                    Rectangle {
                        id: appPop
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width + 6
                        width: 190; height: appPopCol.implicitHeight + 20
                        radius: 14; color: win.cBg
                        border.color: win.cRim; border.width: 1; antialiasing: true
                        transformOrigin: Item.Left
                        scale: appArea.popOpen ? 1.0 : 0.78
                        opacity: appArea.popOpen ? 1.0 : 0.0
                        visible: opacity > 0.01
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Column {
                            id: appPopCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                            spacing: 4
                            Rectangle {
                                width: 20; height: 3; radius: 2; color: win.cAccent
                                visible: appArea.isActive
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: modelData; font.pixelSize: 13; color: win.cText
                                width: parent.width; elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: appArea.isActive ? "Em foco" : "Clique para focar"
                                font.pixelSize: 10; color: win.cDim
                                width: parent.width; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: appCloseT.stop()
                            onExited:  appCloseT.restart()
                            onClicked: { appFocProc.title = modelData; appFocProc.running = true }
                        }
                    }
                }
            }

            Rectangle {
                width: 24; height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: win.cRim; visible: win.openApps.length > 0
            }

            // Música
            Item {
                width: 44; height: 36; anchors.horizontalCenter: parent.horizontalCenter
                visible: win.musicStatus !== ""
                Text {
                    anchors.centerIn: parent; text: "\u266A"; font.pixelSize: 20
                    color: win.musicStatus === "playing" ? win.cAccent : win.cDim
                    SequentialAnimation on opacity {
                        running: win.musicStatus === "playing"; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Volume
            Item {
                id: volArea; width: 44; height: 42
                anchors.horizontalCenter: parent.horizontalCenter
                property bool popOpen: false

                Rectangle {
                    anchors { fill: parent; margins: 2 }
                    radius: 10
                    color: volArea.popOpen ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                Text {
                    anchors.centerIn: parent; font.pixelSize: 20
                    color: volArea.popOpen ? win.cAccent : win.cDim
                    rotation: volArea.popOpen ? -15 : 0
                    Behavior on color    { ColorAnimation  { duration: 130 } }
                    Behavior on rotation { RotationAnimation { duration: 300; easing.type: Easing.OutBack } }
                    text: {
                        if (win.volumeLevel === 0) return "\uD83D\uDD07"
                        if (win.volumeLevel < 40)  return "\uD83D\uDD08"
                        if (win.volumeLevel < 70)  return "\uD83D\uDD09"
                        return "\uD83D\uDD0A"
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { volCloseT.stop(); volArea.popOpen = true }
                    onExited:  volCloseT.restart()
                }
                Timer { id: volCloseT; interval: 350; onTriggered: volArea.popOpen = false }

                Rectangle {
                    id: volPop
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width + 6
                    width: 190; height: volPopCol.implicitHeight + 20
                    radius: 14; color: win.cBg
                    border.color: win.cRim; border.width: 1; antialiasing: true
                    transformOrigin: Item.Left
                    scale: volArea.popOpen ? 1.0 : 0.78
                    opacity: volArea.popOpen ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Column {
                        id: volPopCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 8
                        Text { text: "VOLUME"; font.pixelSize: 9; font.letterSpacing: 1.2; font.weight: Font.Medium; color: win.cDim }
                        Row {
                            spacing: 10
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.volumeLevel + "%"; font.pixelSize: 26; font.weight: Font.Bold; color: win.cText
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Repeater {
                                    model: ["+5%", "-5%"]
                                    delegate: Rectangle {
                                        width: 38; height: 22; radius: 6; color: Qt.rgba(1,1,1,0.08)
                                        Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 12; color: win.cText }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: { vcProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", modelData]; vcProc.running = true }
                                        }
                                        Process { id: vcProc; running: false; command: []; onExited: { running = false; volRefreshT.restart() } }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.10)
                            Rectangle {
                                width: parent.width * (win.volumeLevel / 100)
                                height: parent.height; radius: parent.radius; color: win.cAccent
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: volCloseT.stop()
                        onExited:  volCloseT.restart()
                    }
                }
            }
        }
    }

    // ── PROCESSOS ──────────────────────────────────────────────
    Process {
        id: hyprProc; running: false
        command: [
            "sh", "-c",
            "hyprctl clients -j 2>/dev/null | python3 -c \"import sys,json,subprocess as sp\nc=json.load(sys.stdin)\nt=[x['title'] for x in c if x.get('title','').strip()]\nprint('APPS:'+','.join(t[:7]))\ntry:\n a=json.loads(sp.check_output(['hyprctl','activewindow','-j'],stderr=sp.DEVNULL))\n print('FOCUS:'+a.get('title',''))\n print('MAX:'+str(int(bool(a.get('fullscreen',False)))))\nexcept:\n print('FOCUS:')\n print('MAX:0')\n\""
        ]
        stdout: SplitParser {
            onRead: function(d) {
                if (d.startsWith("APPS:"))
                    win.openApps = d.slice(5).split(",").filter(function(t) { return t.length > 0 })
                else if (d.startsWith("FOCUS:"))
                    win.focusedApp = d.slice(6).trim()
                else if (d.startsWith("MAX:"))
                    win.isMaximized = d.slice(4).trim() === "1"
            }
        }
        onExited: running = false
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { hyprProc.running = false; hyprProc.running = true } }

    Process {
        id: volProc; running: false
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%'"]
        stdout: SplitParser { onRead: function(d) { win.volumeLevel = parseInt(d.trim()) || 0 } }
        onExited: running = false
    }
    Timer { id: volRefreshT; interval: 4000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { volProc.running = false; volProc.running = true } }

    Process {
        id: musicProc; running: false
        command: ["sh", "-c", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: SplitParser {
            onRead: function(d) {
                var s = d.trim().toLowerCase()
                win.musicStatus = (s === "playing" || s === "paused") ? s : ""
            }
        }
        onExited: running = false
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { musicProc.running = false; musicProc.running = true } }
}
