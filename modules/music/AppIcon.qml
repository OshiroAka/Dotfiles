import QtQuick

Rectangle {
    id: root

    property string iconSource: ""
    property color  bgColor:    "#1DB954"
    property bool   pulsing:    false
    signal clicked()

    width: 32; height: 32; radius: 16
    color: bgColor
    antialiasing: true

    // Pulso independente do hover
    property real pulseScale: 1.0
    SequentialAnimation on pulseScale {
        loops: Animation.Infinite
        running: root.pulsing
        NumberAnimation { to: 1.13; duration: 580; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0;  duration: 580; easing.type: Easing.InOutSine }
    }
    onPulsingChanged: { if (!pulsing) pulseScale = 1.0 }

    // Hover independente
    property real hoverScale: 1.0
    Behavior on hoverScale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

    scale: pulseScale * hoverScale

    Image {
        anchors.centerIn: parent
        width: 20; height: 20
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered:  root.hoverScale = 1.22
        onExited:   root.hoverScale = 1.0
        onClicked:  root.clicked()
    }
}
