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

    property real pulseScale: 1.0
    property real hoverScale: 1.0
    scale: pulseScale * hoverScale

    function startPulse() {
        pulseAnim.stop()
        pulseScale = 1.0
        pulseAnim.start()
    }
    function stopPulse() {
        pulseAnim.stop()
        pulseScale = 1.0
    }

    // Dispara quando o valor muda
    onPulsingChanged: {
        if (pulsing) startPulse()
        else stopPulse()
    }

    // Dispara quando o componente e criado (caso ja comece pulsing=true)
    Component.onCompleted: {
        if (pulsing) startPulse()
    }

    SequentialAnimation {
        id: pulseAnim
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "pulseScale"; to: 1.13; duration: 580; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "pulseScale"; to: 1.0;  duration: 580; easing.type: Easing.InOutSine }
    }

    Behavior on hoverScale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

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
