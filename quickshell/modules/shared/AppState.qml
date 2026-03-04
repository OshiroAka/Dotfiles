import Quickshell
pragma Singleton

Singleton {
    property bool overlayOpen: false
    property real animSpeed:   1.0

    function animDuration(ms) {
        return Math.round(ms * animSpeed)
    }
}
