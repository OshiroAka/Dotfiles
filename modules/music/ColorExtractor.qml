import QtQuick

Item {
    id: root
    width: 1; height: 1
    visible: false

    property string imageSource: ""
    property color  dominantColor: "#1DB954"  // fallback verde

    // Imagem oculta para o canvas ler
    Image {
        id: srcImage
        source: root.imageSource
        width: 32; height: 32
        visible: false
        cache: true
        onStatusChanged: {
            if (status === Image.Ready)
                extractCanvas.requestPaint()
        }
    }

    Canvas {
        id: extractCanvas
        width: 32; height: 32
        visible: false

        onPaint: {
            var ctx = getContext("2d")
            ctx.drawImage(srcImage, 0, 0, 32, 32)

            var bestR = 0, bestG = 0, bestB = 0
            var bestScore = -1

            // Amostra 64 pontos numa grade 8x8
            for (var x = 2; x < 32; x += 4) {
                for (var y = 2; y < 32; y += 4) {
                    var px = ctx.getImageData(x, y, 1, 1).data
                    var r = px[0], g = px[1], b = px[2]

                    // Calcula saturacao (quao colorida e a cor)
                    var max = Math.max(r, g, b)
                    var min = Math.min(r, g, b)
                    var sat = max === 0 ? 0 : (max - min) / max
                    // Preferir cores vivas e nao muito escuras
                    var brightness = (r + g + b) / 3
                    var score = sat * 2 + (brightness / 255)

                    if (score > bestScore) {
                        bestScore = score
                        bestR = r; bestG = g; bestB = b
                    }
                }
            }

            // So atualiza se encontrou algo util
            if (bestScore > 0.3) {
                root.dominantColor = Qt.rgba(bestR/255, bestG/255, bestB/255, 1)
            } else {
                root.dominantColor = "#1DB954"
            }
        }
    }

    // Re-extrai quando a imagem muda
    onImageSourceChanged: {
        if (imageSource !== "")
            extractCanvas.requestPaint()
        else
            dominantColor = "#1DB954"
    }
}
