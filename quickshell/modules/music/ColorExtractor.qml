import QtQuick

Item {
    id: root
    property string imageSource: ""
    property color  dominantColor: "#1DB954"
    visible: false

    Canvas {
        id: canvas
        width: 32; height: 32
        visible: false

        onPaint: {
            var ctx = getContext("2d")
            ctx.drawImage(root.imageSource, 0, 0, 32, 32)
            var data = ctx.getImageData(0, 0, 32, 32).data
            var r = 0, g = 0, b = 0, count = 0
            for (var i = 0; i < data.length; i += 16) {
                r += data[i]; g += data[i+1]; b += data[i+2]; count++
            }
            if (count > 0) root.dominantColor = Qt.rgba(r/count/255, g/count/255, b/count/255, 1)
        }

        onImageLoaded: requestPaint()
    }

    onImageSourceChanged: {
        if (imageSource !== "") canvas.loadImage(imageSource)
    }
}
