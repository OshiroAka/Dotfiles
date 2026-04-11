import QtQuick
import QtQuick.Controls

Row {
    property string label: ""
    property bool   checked: false
    signal checkedChanged(bool checked)
    spacing: 12
    anchors.left: parent.left

    Text {
        text: label
        color: Qt.rgba(1,1,1,0.7)
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 260
    }

    Rectangle {
        width: 44; height: 24; radius: 12
        color: parent.checked ? "#1DB954" : Qt.rgba(1,1,1,0.12)
        Behavior on color { ColorAnimation { duration: 180 } }
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 18; height: 18; radius: 9
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: parent.checked ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                parent.parent.checked = !parent.parent.checked
                parent.parent.checkedChanged(parent.parent.checked)
            }
        }
    }
}
