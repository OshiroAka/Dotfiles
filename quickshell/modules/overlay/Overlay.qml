import Quickshell
import Quickshell.Wayland
import QtQuick
import "../shared"

PanelWindow {
    id: overlay
    anchors.top: true
    anchors.left: true
    margins.top: 52
    margins.left: (screen ? (screen.width - 900) / 2 : 510)   // logo abaixo do pill (36px + 8px margin + 8px gap)
    color: "transparent"

    // Janela FIXA
    implicitWidth:  900
    implicitHeight: 420

    // Fecha com ESC
    Shortcut {
        sequence: "Escape"
        onActivated: AppState.overlayOpen = false
    }

    // Panel container
    Item {
        anchors.fill: parent

        Rectangle {
            id: panel
            anchors.centerIn: parent
            antialiasing: true
            layer.enabled: true

            width:  AppState.overlayOpen ? 900 : 800
            height: AppState.overlayOpen ? 420 : 36
            radius: AppState.overlayOpen ? 24  : 18

            Behavior on width  { SmoothedAnimation { duration: AppState.animDuration(400); easing.type: Easing.InOutCubic } }
            Behavior on height { SmoothedAnimation { duration: AppState.animDuration(360); easing.type: Easing.InOutCubic } }
            Behavior on radius { SmoothedAnimation { duration: AppState.animDuration(360); easing.type: Easing.InOutCubic } }

            // Fundo
            color: Qt.rgba(0.06, 0.06, 0.10, AppState.panelOpacity)

            // Borda
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.08)
                border.width: 1; antialiasing: true; z: 10
            }

            // Conteudo — so aparece apos animacao
            property bool contentVisible: false
            Timer {
                id: contentTimer
                interval: AppState.animDuration(420)
                repeat: false
                onTriggered: panel.contentVisible = AppState.overlayOpen
            }
            onWidthChanged: {
                if (!AppState.overlayOpen) panel.contentVisible = false
            }

            Connections {
                target: AppState
                function onOverlayOpenChanged() {
                    if (AppState.overlayOpen) {
                        panel.contentVisible = false
                        contentTimer.restart()
                    } else {
                        panel.contentVisible = false
                    }
                }
            }

            // ── Tabs ──
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                opacity: panel.contentVisible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: AppState.animDuration(200); easing.type: Easing.OutCubic }
                }

                // Tab bar
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: ["Wallpaper", "Temas", "Configurações", "Apps", "Créditos"]

                        Rectangle {
                            width:  tabLabel.implicitWidth + 28
                            height: 36
                            radius: 18
                            antialiasing: true

                            color: AppState.activeTab === modelData.toLowerCase() ?
                                Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.05)

                            Behavior on color { ColorAnimation { duration: AppState.animDuration(180) } }

                            // Escala ao selecionar
                            scale: AppState.activeTab === modelData.toLowerCase() ? 1.06 : 1.0
                            Behavior on scale { NumberAnimation { duration: AppState.animDuration(180); easing.type: Easing.OutBack } }

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: AppState.activeTab === modelData.toLowerCase() ?
                                    "white" : Qt.rgba(1,1,1,0.5)
                                font.pixelSize: 13
                                font.weight: AppState.activeTab === modelData.toLowerCase() ?
                                    Font.SemiBold : Font.Normal
                                Behavior on color { ColorAnimation { duration: AppState.animDuration(180) } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppState.activeTab = modelData.toLowerCase()
                            }
                        }
                    }
                }

                // Conteudo da tab ativa
                Loader {
                    width: parent.width
                    height: parent.height - 36 - 12
                    source: {
                        switch(AppState.activeTab) {
                            case "wallpaper":     return "tabs/WallpaperTab.qml"
                            case "temas":         return "tabs/ThemesTab.qml"
                            case "configurações": return "tabs/SettingsTab.qml"
                            case "apps":          return "tabs/AppsTab.qml"
                            case "créditos":      return "tabs/CreditsTab.qml"
                            default:              return "tabs/WallpaperTab.qml"
                        }
                    }
                }
            }

            // Click fora fecha
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: AppState.overlayOpen = false
            }
        }
    }
}
