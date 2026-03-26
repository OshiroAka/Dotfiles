import Quickshell
import Quickshell.Wayland
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "shiraos-config"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; right: true }
    margins.top:   10
    margins.right: 350
    implicitWidth:  36
    implicitHeight: 36
    color: "transparent"
    focusable: false

    Rectangle {
        anchors.fill: parent; radius: 18
        color: AppState.configOpen ? Qt.rgba(0.29,0.62,1.0,0.25) : (AppState.accentPill || Qt.rgba(0.06,0.06,0.12,0.30))
        border.color: AppState.accentBorder || Qt.rgba(0.30,0.30,0.60,0.25); border.width: 1; antialiasing: true
        Behavior on color { ColorAnimation { duration: 400 } }
        Text {
            anchors.centerIn: parent
            font.family: AppState.iconFont || "MesloLGS Nerd Font"
            font.pixelSize: 15; text: ""
            color: AppState.configOpen ? (AppState.accentColor||Qt.rgba(0.29,0.62,1,1)) : Qt.rgba(1,1,1,0.65)
            rotation: AppState.configOpen ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            Behavior on color    { ColorAnimation { duration: 200 } }
        }
        MouseArea {
            anchors.fill: parent
            onPressed: AppState.configOpen = !(AppState.configOpen || false)
        }
    }
}
