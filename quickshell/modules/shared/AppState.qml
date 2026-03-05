import Quickshell
pragma Singleton

Singleton {
    property bool overlayOpen: false
    property string overlayCurrentTab: ""
    property int staticWallIdx: 0
    property int liveWallIdx: 0
    property int activeWallRow: 0
    property real animSpeed:   1.0

    function animDuration(ms) { return Math.round(ms * animSpeed) }
    function toggle() { overlayOpen = !overlayOpen }

    signal closeDone()
    function overlayFullyClosed() { closeDone() }
}
