import QtQuick

Item {
    id: root
    property string icon: "?"
    property real iconSize: 10
    signal clicked()

    width: 28
    height: 28

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: area.containsMouse ? "white" : Qt.rgba(1,1,1,0.65)
        font.pixelSize: root.iconSize
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }

    Rectangle {
        anchors.centerIn: parent
        width: 22; height: 22; radius: 11
        color: Qt.rgba(1,1,1,0.1)
        opacity: area.pressed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }
}
