import QtQuick

Item {
    id: card
    property real cardWidth: 200
    property real cardHeight: 100
    property bool active: false
    property string thumbSource: ""
    property bool isVideo: false
    signal activated()

    width: cardWidth; height: cardHeight

    scale:   active ? 1.0 : 0.82
    opacity: active ? 1.0 : 0.50
    Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Rectangle {
        anchors.fill: parent
        radius: 10; color: "#0a0a0a"; clip: true

        AnimatedImage {
            anchors.fill: parent
            source: thumbSource
            fillMode: Image.PreserveAspectCrop
            smooth: true; asynchronous: true
            playing: active
        }

        // Badge video
        Rectangle {
            visible: isVideo
            anchors.top: parent.top; anchors.right: parent.right
            anchors.margins: 6
            width: 24; height: 16; radius: 4
            color: Qt.rgba(0,0,0,0.7)
            Text { anchors.centerIn: parent; text: "▶"; color: "white"; font.pixelSize: 9 }
        }

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.color: active ? Qt.rgba(1,1,1,0.6) : Qt.rgba(1,1,1,0.08)
            border.width: active ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
