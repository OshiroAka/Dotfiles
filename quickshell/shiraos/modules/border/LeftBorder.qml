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
    implicitWidth: 328
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    property int    volumeLevel:     50
    property bool   batteryPresent:  false
    property int    batteryLevel:    100
    property bool   batteryCharging: false
    property var    openApps:        []
    property string focusedApp:      ""
    property bool   isMaximized:     false
    property string musicStatus:     ""

    property color cAccent: Qt.rgba(0.29, 0.62, 1.0,  1.0)
    property color cBg:     Qt.rgba(0.05, 0.08, 0.16, 0.42)
    property color cRim:    Qt.rgba(0.25, 0.45, 0.80, 0.32)
    property color cText:   Qt.rgba(1.0,  1.0,  1.0,  0.90)
    property color cDim:    Qt.rgba(1.0,  1.0,  1.0,  0.45)

    // Adaptive color via polling — Connections nao funciona com singleton customizado
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var a = AppState.accentColor
            if (!a) return
            win.cAccent = a
            win.cBg  = Qt.rgba(a.r * 0.14 + 0.03, a.g * 0.14 + 0.03, a.b * 0.16 + 0.04, 0.42)
            win.cRim = Qt.rgba(a.r * 0.60 + 0.10, a.g * 0.60 + 0.10, a.b * 0.60 + 0.10, 0.32)
        }
    }

    // ── PILL ───────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors {
            top: parent.top; bottom: parent.bottom; left: parent.left
            topMargin: 10; bottomMargin: 10; leftMargin: 8
        }
        width: 44; radius: 22; color: win.cBg
        border.color: win.cRim; border.width: 1; antialiasing: true
        opacity: win.isMaximized ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 260 } }

        // Relógio
        Item {
            id: clockItem
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 16 }
            width: 40; height: 40
            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(new Date(), "HH")
                font.pixelSize: 14; font.weight: Font.Bold; color: win.cText
            }
            Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH") }
        }

        Rectangle {
            id: sep1
            anchors { top: clockItem.bottom; horizontalCenter: parent.horizontalCenter; topMargin: 6 }
            width: 24; height: 1; color: win.cRim
        }

        // Botão power no fundo
        Column {
            id: sysButtons
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
            spacing: 0

            Rectangle { width: 24; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: win.cRim }

            // Power button + popup
            Item {
                id: powerArea
                width: 44; height: 40
                anchors.horizontalCenter: parent.horizontalCenter

                property bool hovered: powerMA.containsMouse || powerPopup.open

                Rectangle {
                    anchors { fill: parent; margins: 2 }
                    radius: 10
                    color: powerArea.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "\u23FB"; font.pixelSize: 18
                    color: powerArea.hovered ? Qt.rgba(1, 0.45, 0.45, 1) : win.cDim
                    Behavior on color { ColorAnimation { duration: 130 } }
                }

                MouseArea {
                    id: powerMA
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { powerCloseT.stop(); powerPopup.open = true }
                    onExited:  powerCloseT.restart()
                }

                // Popup power — ancorado ao item
                Rectangle {
                    id: powerPopup
                    property bool open: false

                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width + 6
                    width: 190; height: pwCol.implicitHeight + 20
                    radius: 14; color: win.cBg
                    border.color: win.cRim; border.width: 1; antialiasing: true

                    transformOrigin: Item.Left
                    scale: open ? 1.0 : 0.78
                    opacity: open ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Column {
                        id: pwCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 2

                        Text { text: "SISTEMA"; font.pixelSize: 9; font.letterSpacing: 1.2; font.weight: Font.Medium; color: win.cDim }

                        Repeater {
                            model: [
                                { label: "Bloquear",  icon: "\uD83D\uDD12", cmd: ["loginctl", "lock-session"] },
                                { label: "Suspender", icon: "\u23FE",        cmd: ["systemctl", "suspend"]    },
                                { label: "Reiniciar", icon: "\u21BA",        cmd: ["systemctl", "reboot"]     },
                                { label: "Desligar",  icon: "\u23FB",        cmd: ["systemctl", "poweroff"]   }
                            ]
                            delegate: Item {
                                id: pwRow; width: parent.width; height: 34
                                property bool hovered: false
                                Rectangle { anchors.fill: parent; radius: 8; color: pwRow.hovered ? Qt.rgba(0.9,0.2,0.2,0.12) : "transparent"; Behavior on color { ColorAnimation { duration: 120 } } }
                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 10
                                    Text { text: modelData.icon; font.pixelSize: 15; color: win.cDim }
                                    Text { text: modelData.label; font.pixelSize: 13; color: win.cText }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: pwRow.hovered = true
                                    onExited:  pwRow.hovered = false
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

                Timer { id: powerCloseT; interval: 350; onTriggered: powerPopup.open = false }
            }
        }

        // ── Meio: apps + volume ────────────────────────────────
        Column {
            id: midCol
            anchors {
                top: sep1.bottom; bottom: sysButtons.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 6; bottomMargin: 6
            }
            spacing: 4

            // Apps
            Repeater {
                model: win.openApps.slice(0, 6)
                delegate: Item {
                    id: appArea; width: 44; height: 38
                    anchors.horizontalCenter: parent.horizontalCenter
                    property bool hovered: appMA.containsMouse || appPop.open
                    property bool isActive: modelData === win.focusedApp

                    // Indicador lateral
                    Rectangle {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 2 }
                        width: 3; radius: 2; color: win.cAccent
                        height: appArea.isActive ? 20 : (appArea.hovered ? 12 : 5)
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    // Fundo hover
                    Rectangle {
                        anchors { fill: parent; leftMargin: 6; margins: 2 }
                        radius: 10
                        color: appArea.hovered ? Qt.rgba(1,1,1,0.10) : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    // Letra
                    Text {
                        anchors { centerIn: parent; horizontalCenterOffset: 3 }
                        text: modelData.charAt(0).toUpperCase()
                        font.pixelSize: 16; font.weight: Font.Medium
                        color: appArea.isActive ? win.cAccent : (appArea.hovered ? win.cText : win.cDim)
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    MouseArea {
                        id: appMA; anchors.fill: parent; hoverEnabled: true
                        onEntered: { appCloseT.stop(); appPop.open = true }
                        onExited:  appCloseT.restart()
                        onClicked: { appFocProc.title = modelData; appFocProc.running = true }
                    }
                    Timer { id: appCloseT; interval: 350; onTriggered: appPop.open = false }
                    Process { id: appFocProc; running: false; property string title: ""; command: ["hyprctl", "dispatch", "focuswindow", "title:" + title]; onExited: running = false }

                    // Popup
                    Rectangle {
                        id: appPop; property bool open: false
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width + 6
                        width: 190; height: appPopCol.implicitHeight + 20
                        radius: 14; color: win.cBg
                        border.color: win.cRim; border.width: 1; antialiasing: true
                        transformOrigin: Item.Left
                        scale: open ? 1.0 : 0.78
                        opacity: open ? 1.0 : 0.0
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

            Rectangle { width: 24; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: win.cRim; visible: win.openApps.length > 0 }

            // Música
            Item {
                width: 44; height: 32; anchors.horizontalCenter: parent.horizontalCenter
                visible: win.musicStatus !== ""
                Text {
                    anchors.centerIn: parent; text: "\u266A"; font.pixelSize: 18
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
                id: volArea; width: 44; height: 38
                anchors.horizontalCenter: parent.horizontalCenter
                property bool hovered: volMA.containsMouse || volPop.open

                Rectangle {
                    anchors { fill: parent
                    margins: 2 }
                    radius: 10
                    color: volArea.hovered ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                Text {
                    anchors.centerIn: parent; font.pixelSize: 18
                    color: volArea.hovered ? win.cAccent : win.cDim
                    Behavior on color { ColorAnimation { duration: 130 } }
                    text: {
                        if (win.volumeLevel === 0) return "\uD83D\uDD07"
                        if (win.volumeLevel < 40)  return "\uD83D\uDD08"
                        if (win.volumeLevel < 70)  return "\uD83D\uDD09"
                        return "\uD83D\uDD0A"
                    }
                }

                MouseArea {
                    id: volMA; anchors.fill: parent; hoverEnabled: true
                    onEntered: { volCloseT.stop(); volPop.open = true }
                    onExited:  volCloseT.restart()
                }
                Timer { id: volCloseT; interval: 350; onTriggered: volPop.open = false }

                Rectangle {
                    id: volPop; property bool open: false
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width + 6
                    width: 190; height: volPopCol.implicitHeight + 20
                    radius: 14; color: win.cBg
                    border.color: win.cRim; border.width: 1; antialiasing: true
                    transformOrigin: Item.Left
                    scale: open ? 1.0 : 0.78
                    opacity: open ? 1.0 : 0.0
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
                            Text { anchors.verticalCenter: parent.verticalCenter; text: win.volumeLevel + "%"; font.pixelSize: 26; font.weight: Font.Bold; color: win.cText }
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
                            Rectangle { width: parent.width * (win.volumeLevel / 100); height: parent.height; radius: parent.radius; color: win.cAccent; Behavior on width { NumberAnimation { duration: 300 } } }
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
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { hyprProc.running = false; hyprProc.running = true } }

    Process {
        id: volProc; running: false
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%'"]
        stdout: SplitParser { onRead: function(d) { win.volumeLevel = parseInt(d.trim()) || 0 } }
        onExited: running = false
    }
    Timer { id: volRefreshT; interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { volProc.running = false; volProc.running = true } }

    Process {
        id: musicProc; running: false
        command: ["sh", "-c", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: SplitParser { onRead: function(d) { var s = d.trim().toLowerCase(); win.musicStatus = (s === "playing" || s === "paused") ? s : "" } }
        onExited: running = false
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { musicProc.running = false; musicProc.running = true } }
}
