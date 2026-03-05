import QtQuick

Item {
    id: root
    property real  blurRadius: 32
    property real  cornerRadius: 20
    property color tintColor: Qt.rgba(0.06, 0.06, 0.10, 0.45)

    // Captura o que está atrás
    ShaderEffectSource {
        id: bgSource
        sourceItem: null   // será setado pelo pai
        hideSource: false
        live: true
        anchors.fill: parent
        visible: false
    }

    // Blur horizontal
    ShaderEffect {
        id: blurH
        anchors.fill: parent
        visible: false
        property var src: bgSource
        property real stepW: blurRadius / width

        fragmentShader: "
            uniform sampler2D src;
            uniform float stepW;
            varying vec2 qt_TexCoord0;
            void main() {
                vec4 c = vec4(0.0);
                float w = 0.0;
                for (int i = -8; i <= 8; i++) {
                    float weight = exp(-0.5 * float(i*i) / 9.0);
                    c += texture2D(src, qt_TexCoord0 + vec2(float(i) * stepW, 0.0)) * weight;
                    w += weight;
                }
                gl_FragColor = c / w;
            }
        "
    }

    ShaderEffectSource {
        id: blurHSource
        sourceItem: blurH
        hideSource: true
        live: true
        anchors.fill: parent
        visible: false
    }

    // Blur vertical
    ShaderEffect {
        id: blurV
        anchors.fill: parent
        property var src: blurHSource
        property real stepH: blurRadius / height
        visible: false

        fragmentShader: "
            uniform sampler2D src;
            uniform float stepH;
            varying vec2 qt_TexCoord0;
            void main() {
                vec4 c = vec4(0.0);
                float w = 0.0;
                for (int i = -8; i <= 8; i++) {
                    float weight = exp(-0.5 * float(i*i) / 9.0);
                    c += texture2D(src, qt_TexCoord0 + vec2(0.0, float(i) * stepH)) * weight;
                    w += weight;
                }
                gl_FragColor = c / w;
            }
        "
    }

    ShaderEffectSource {
        id: blurVSource
        sourceItem: blurV
        hideSource: true
        live: true
        anchors.fill: parent
        visible: false
    }

    // Composita blur + tint + rounded corners
    ShaderEffect {
        anchors.fill: parent
        property var blurred: blurVSource
        property color tint: root.tintColor
        property real radius: root.cornerRadius
        property real w: width
        property real h: height

        fragmentShader: "
            uniform sampler2D blurred;
            uniform vec4 tint;
            uniform float radius;
            uniform float w;
            uniform float h;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 pos = qt_TexCoord0 * vec2(w, h);
                vec2 corner = vec2(radius);
                vec2 q = abs(pos - vec2(w,h)*0.5) - vec2(w,h)*0.5 + corner;
                float d = length(max(q, 0.0)) - radius;
                float alpha = clamp(-d, 0.0, 1.0);
                vec4 bg = texture2D(blurred, qt_TexCoord0);
                vec4 result = mix(bg, bg * 0.5 + tint, tint.a) ;
                gl_FragColor = vec4(result.rgb, alpha);
            }
        "
    }
}
