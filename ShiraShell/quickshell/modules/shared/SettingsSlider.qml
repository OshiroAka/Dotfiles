import QtQuick
import QtQuick.Controls

Column {
    property string label: ""
    property real   value: 0.5
    property real   from:  0.0
    property real   to:    1.0
    signal valueChanged(real value)
    spacing: 6

    Text { text: label; color: Qt.rgba(1,1,1,0.7); font.pixelSize: 12 }

    Row {
        spacing: 12
        Slider {
            id: sl
            from: parent.parent.from; to: parent.parent.to
            value: parent.parent.value
            width: 300
            onValueChanged: parent.parent.valueChanged(value)
        }
        Text {
            text: sl.value.toFixed(2)
            color: Qt.rgba(1,1,1,0.5)
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
