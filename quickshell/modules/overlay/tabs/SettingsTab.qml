import QtQuick
import "../../shared"

Item {
    Column {
        anchors.centerIn: parent
        spacing: 20
        width: 400

        // Transparencia
        SettingsSlider {
            label: "Transparência do painel"
            value: AppState.panelOpacity
            from: 0.1; to: 0.9
            onValueChanged: AppState.panelOpacity = value
        }

        // Velocidade das animacoes
        SettingsSlider {
            label: "Velocidade das animações"
            value: AppState.animSpeed
            from: 0.3; to: 2.0
            onValueChanged: AppState.animSpeed = value
        }

        // Blur on/off
        SettingsToggle {
            label: "Blur"
            checked: AppState.blurEnabled
            onCheckedChanged: AppState.blurEnabled = checked
        }

        // Tipo wallpaper
        SettingsToggle {
            label: "Wallpapers animados (live)"
            checked: AppState.wallpaperType === "live"
            onCheckedChanged: AppState.wallpaperType = checked ? "live" : "static"
        }

        // Engine
        SettingsToggle {
            label: "Usar mpvpaper (live/vídeo)"
            checked: AppState.wallpaperEngine === "mpvpaper"
            onCheckedChanged: AppState.wallpaperEngine = checked ? "mpvpaper" : "swww"
        }
    }
}
