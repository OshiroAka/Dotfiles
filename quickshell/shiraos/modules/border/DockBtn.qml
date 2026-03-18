import Quickshell
import Quickshell.Io
import QtQuick
import ShiraOS

Item {
    id: root
    property string btnIcon:  ""
    property string btnLabel: ""
    property string btnCmd:   ""
    property bool   isActive: false
    property bool   vertical: false

    property color cAccent: Qt.rgba(0.29, 0.62, 1.0, 1.0)
    property color cBg:     Qt.rgba(0.06, 0.06, 0.12, 0.30)
    property color cRim:    Qt.rgba(0.30, 0.30, 0.60, 0.25)
    property color cText:   Qt.rgba(1.0,  1.0,  1.0,  0.90)
    property color cDim:    Qt.rgba(1.0,  1.0,  1.0,  0.45)

    property bool hov: false

    width:  vertical ? 50 : 52
    height: vertical ? 44 : 60

    Rectangle {
        visible: !vertical
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 4
        width: root.isActive ? 18 : (root.hov ? 8 : 0); height: 3; radius: 2; color: root.cAccent
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        visible: vertical
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 2
        width: 3; radius: 2; color: root.cAccent
        height: root.isActive ? 20 : (root.hov ? 12 : 5)
        Behavior on height { NumberAnimation { duration: 160 } }
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: vertical ? 2 : 4; anchors.leftMargin: vertical ? 6 : 4
        radius: vertical ? 10 : 14
        color: root.hov ? Qt.rgba(1,1,1,0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 130 } }
    }
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: vertical ? 0 : -3
        anchors.horizontalCenterOffset: vertical ? 3 : 0
        text: root.btnIcon
        font.family: AppState.iconFont
        font.pixelSize: vertical ? 19 : 22
        color: root.isActive ? root.cAccent : (root.hov ? root.cText : root.cDim)
        Behavior on color { ColorAnimation { duration: 130 } }
    }
    MouseArea {
        anchors.fill: parent; hoverEnabled: true
        onEntered: root.hov = true; onExited: root.hov = false
        onClicked: launchProc.running = true
    }
    Process { id: launchProc; running: false; command: ["sh", "-c", root.btnCmd + " &"]; onExited: running = false }

    Rectangle {
        visible: root.hov
        anchors.bottom:  vertical ? undefined : parent.top
        anchors.left:    vertical ? parent.right : undefined
        anchors.verticalCenter: vertical ? parent.verticalCenter : undefined
        anchors.horizontalCenter: vertical ? undefined : parent.horizontalCenter
        anchors.bottomMargin: vertical ? 0 : 6
        anchors.leftMargin:   vertical ? 8 : 0
        width: tipTxt.implicitWidth + 16; height: 26; radius: 8
        color: root.cBg; border.color: root.cRim; border.width: 1
        Text { id: tipTxt; anchors.centerIn: parent; text: root.btnLabel; font.family: AppState.globalFont; font.pixelSize: 11; color: root.cText }
    }
}
