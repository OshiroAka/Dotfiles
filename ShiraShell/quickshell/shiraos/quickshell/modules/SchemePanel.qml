import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "shiraos-panel"
    WlrLayershell.exclusiveZone: -1
    anchors { top: true; right: true }
    margins.top:   10
    margins.right: 10
    implicitWidth:  320
    implicitHeight: 430
    color: Qt.rgba(0, 0, 0, 0.01)
    focusable: false

    Region { id: emptyMask }
    mask: win.panelScale > 0.01 ? null : emptyMask

    property bool extracting:     false
    property bool extracted:      false
    property real panelScale:     0.0
    property real panelOpacity:   0.0
    property string wallpaperPath: ""
    property string accentHex:    ""

    function pillColor()   { return AppState.accentPill   || Qt.rgba(0.06,0.06,0.12,0.75) }
    function darkCol()     { return AppState.accentDark   || Qt.rgba(0.08,0.08,0.14,0.92) }
    function borderColor() { return AppState.accentBorder || Qt.rgba(0.3,0.3,0.6,0.25)    }
    function accentCol()   { return AppState.accentColor  || Qt.rgba(0.55,0.55,1.0,1.0)   }

    Connections {
        target: AppState
        function onSchemeOpenChanged() {
            if (AppState.schemeOpen) openAnim.start()
            else closeAnim.start()
        }
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: win; property: "panelOpacity"; to: 1.0; duration: 80 }
        NumberAnimation { target: win; property: "panelScale"; to: 1.0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: win; property: "panelScale"; to: 0.55; duration: 260; easing.type: Easing.InBack; easing.overshoot: 1.8 }
        NumberAnimation { target: win; property: "panelOpacity"; to: 0.0; duration: 80 }
    }

    Process {
        id: wpQuery
        command: ["bash", "-c", "swww query | grep -o 'image:.*' | head -1 | sed 's/image: //'"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.trim()
                if (p.length > 0) win.wallpaperPath = p
            }
        }
    }
    Timer {
        interval: 4000; repeat: true; running: true
        onTriggered: {
            wpQuery.running = false
            wpQuery.running = true
        }
    }

    Rectangle {
        anchors.top:    parent.top
        anchors.right:  parent.right
        width: 310; height: 420
        radius: 20
        color:  win.darkCol()
        border.color: win.borderColor()
        border.width: 1
        transformOrigin: Item.TopRight
        scale:   win.panelScale
        opacity: win.panelOpacity
        visible: win.panelScale > 0.01
        clip:    true
        Behavior on color { ColorAnimation { duration: 600 } }

        Column {
            anchors.fill:    parent
            anchors.margins: 16
            spacing:         12
            opacity: win.panelOpacity
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                text: "Scheme Adaptativo"
                color: Qt.rgba(1,1,1,0.9)
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: "Extrai as cores do wallpaper\ne aplica em todo o ShiraOS"
                color: Qt.rgba(1,1,1,0.45)
                font.pixelSize: 11
                lineHeight: 1.4
            }

            Rectangle {
                width: parent.width; height: 150
                radius: 12; color: Qt.rgba(0,0,0,0.3); clip: true
                Image {
                    anchors.fill: parent
                    source: win.wallpaperPath.length > 0 ? "file://" + win.wallpaperPath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 44
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.01) }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.65) }
                    }
                }
                Text {
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    anchors.bottomMargin: 8; anchors.leftMargin: 10
                    text: win.accentHex.length > 0 ? win.accentHex : "—"
                    color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11; font.family: "monospace"
                }
            }

            Row {
                spacing: 5; visible: win.extracted
                Repeater {
                    model: 5
                    Rectangle {
                        width: (278-20)/5; height: 22; radius: 6
                        color: {
                            var cols = [AppState.accentColor, AppState.accentPill,
                                        AppState.accentBorder, AppState.accentDark,
                                        Qt.rgba(0.07,0.07,0.09,1)]
                            return cols[index] || Qt.rgba(0.2,0.2,0.2,1)
                        }
                        Behavior on color { ColorAnimation { duration: 800 } }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 46; radius: 23
                color: win.extracting ? Qt.rgba(0.1,0.1,0.2,0.6) : win.pillColor()
                border.color: win.borderColor(); border.width: 1; clip: true
                Behavior on color { ColorAnimation { duration: 400 } }
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top
                    anchors.bottom: parent.bottom; anchors.margins: 3
                    width: win.extracting ? parent.width - 6 : 0
                    radius: parent.radius; color: Qt.rgba(0.2,0.2,0.5,0.45)
                    Behavior on width { NumberAnimation { duration: 2200; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Text {
                        text: win.extracting ? "⟳" : win.extracted ? "✓" : "✦"
                        color: Qt.rgba(1,1,1,0.9); font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        RotationAnimation on rotation {
                            running: win.extracting
                            from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                        }
                    }
                    Text {
                        text: win.extracting ? "Extraindo..." : win.extracted ? "Aplicado!" : "Extrair Scheme"
                        color: Qt.rgba(1,1,1,0.9); font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: !win.extracting && win.wallpaperPath.length > 0
                    onClicked: {
                        win.extracting = true; win.extracted = false
                        schemeProc.running = false; schemeProc.running = true
                    }
                }
            }

            Row {
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    text: "Auto ao trocar wallpaper"
                    color: Qt.rgba(1,1,1,0.40); font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 38; height: 22; radius: 11
                    color: AppState.autoScheme ? win.pillColor() : Qt.rgba(1,1,1,0.08)
                    border.color: win.borderColor(); border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Rectangle {
                        width: 14; height: 14; radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        x: AppState.autoScheme ? 20 : 4; color: "white"
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: AppState.autoScheme = !AppState.autoScheme
                    }
                }
            }
        }
    }

    Process {
        id: schemeProc
        command: ["/home/oshiro/.local/bin/shiraos-scheme", "apply", win.wallpaperPath]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("ACCENT:")) win.accentHex = line.slice(7).trim()
            }
        }
        onExited: function(code, status) {
            win.extracting = false
            if (code === 0) {
                win.extracted = true
                schemeReadProc.running = false; schemeReadProc.running = true
            }
        }
    }
    Process {
        id: schemeReadProc
        command: ["bash", "-c", "cat ~/.cache/shiraos/current_scheme.json 2>/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var s = JSON.parse(line)
                    if (s.accent)        AppState.accentColor  = s.accent
                    if (s.accent_pill)   AppState.accentPill   = s.accent_pill
                    if (s.accent_border) AppState.accentBorder = s.accent_border
                    if (s.accent_dark)   AppState.accentDark   = s.accent_dark
                } catch(e) {}
            }
        }
    }
}
