import Quickshell
import Quickshell.Wayland
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "shiraos-scheme"
    WlrLayershell.exclusiveZone: -1
    anchors { top: true; right: true }
    margins.top:   10
    margins.right: 10
    implicitWidth:  130
    implicitHeight: 36
    color: Qt.rgba(0, 0, 0, 0.01)
    focusable: false

    Region { id: emptyMask }
    mask: null

    property real pillScale:   1.0
    property real pillOpacity: 1.0

    function pillColor()   { return AppState.accentPill   || Qt.rgba(0.06,0.06,0.12,0.30) }
    function borderColor() { return AppState.accentBorder || Qt.rgba(0.3,0.3,0.6,0.25)    }
    function accentCol()   { return AppState.accentColor  || Qt.rgba(0.55,0.55,1.0,1.0)   }

    Rectangle {
        anchors.centerIn: parent
        width: 130; height: 36; radius: 18
        color:  win.pillColor()
        border.color: win.borderColor()
        border.width: 1
        opacity: win.pillOpacity
        scale:   win.pillScale
        transformOrigin: Item.Center
        Behavior on color { ColorAnimation { duration: 600 } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: "✦"
                color: win.accentCol()
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Scheme"
                color: Qt.rgba(1,1,1,0.85)
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: AppState.schemeOpen = !AppState.schemeOpen
        }
    }
}
