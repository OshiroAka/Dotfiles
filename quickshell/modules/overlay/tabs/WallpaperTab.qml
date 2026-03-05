import QtQuick
import Quickshell.Io
import "../../shared"

Item {
    id: root
    property var staticWalls: []
    property var liveWalls: []
    property int staticIdx: AppState.staticWallIdx
    property int liveIdx: AppState.liveWallIdx
    property int activeRow: AppState.activeWallRow

    Component.onCompleted: { root.forceActiveFocus(); findStatic.running = true; findEngine.running = true }
    onVisibleChanged: if (visible) root.forceActiveFocus()

    Process {
        id: findStatic; running: false
        command: ["bash", "-c", "find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length > 0) { var a = root.staticWalls.slice(); a.push(line); root.staticWalls = a }
            }
        }
    }

    Process {
        id: findEngine; running: false
        command: ["bash", "-c", "for d in ~/.steam/steam/steamapps/workshop/content/431960/*/; do id=$(basename \"$d\"); prev=$(ls \"$d\"preview.* 2>/dev/null | head -1); echo \"$id|$prev\"; done 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("|")
                var a = root.liveWalls.slice()
                a.push({ path: parts[0], preview: parts.length > 1 ? parts[1] : "" })
                root.liveWalls = a
            }
        }
    }

    Timer {
        id: liveDebounce
        interval: 700; repeat: false
        onTriggered: {
            applyLive.running = false
            applyLive.command = [
                "linux-wallpaperengine",
                "--screen-root", "eDP-1",
                "--bg", root.liveWalls[root.liveIdx].path
            ]
            applyLive.running = true
        }
    }

    Process { id: applyStatic; running: false }
    Process { id: applyLive; running: false }
    Process { id: killLive; running: false
        command: ["bash", "-c", "pkill -f linux-wallpaperengine 2>/dev/null; pkill -f mpvpaper 2>/dev/null; true"] }

    function applyStaticWall(idx) {
        if (idx < 0 || idx >= staticWalls.length) return
        staticIdx = idx
        applyStatic.running = false
        applyStatic.command = ["swww", "img", staticWalls[idx],
            "--transition-type", "grow", "--transition-duration", "1", "--transition-fps", "60"]
        Qt.callLater(function() { applyStatic.running = true })
    }

    function applyLiveWall(idx) {
        if (idx < 0 || idx >= liveWalls.length) return
        AppState.liveWallIdx = idx
        applyLive.running = false
        liveDebounce.restart()
    }

    Keys.enabled: true
    Keys.onUpPressed:   AppState.activeWallRow = 0
    Keys.onDownPressed: AppState.activeWallRow = 1
    Keys.onLeftPressed: {
        if (activeRow === 0) applyStaticWall(Math.max(0, staticIdx - 1))
        else applyLiveWall(Math.max(0, liveIdx - 1))
    }
    Keys.onRightPressed: {
        if (activeRow === 0) applyStaticWall(Math.min(staticWalls.length - 1, staticIdx + 1))
        else applyLiveWall(Math.min(liveWalls.length - 1, liveIdx + 1))
    }

    Column {
        anchors.fill: parent; anchors.margins: 8; spacing: 8

        // ── Static row ──
        Row {
            width: parent.width
            height: (parent.height - 8) / 2
            spacing: 8

            Text {
                text: "Static"
                color: root.activeRow === 0 ? "white" : Qt.rgba(1,1,1,0.35)
                font.pixelSize: 11; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter; width: 40
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            ListView {
                id: staticList
                width: parent.width - 48; height: parent.height
                orientation: ListView.Horizontal
                spacing: 8; clip: true
                model: root.staticWalls
                cacheBuffer: Math.max(0, Math.round(height * 16/9) * 3)
                property real cardW: Math.round(height * 16/9)
                currentIndex: root.staticIdx
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width/2 - cardW/2
                preferredHighlightEnd:   width/2 + cardW/2
                Behavior on contentX { SmoothedAnimation { duration: 300; easing.type: Easing.InOutCubic } }

                delegate: Item {
                    id: sDelegate
                    width: staticList.cardW; height: staticList.height
                    property bool active: index === root.staticIdx && root.activeRow === 0
                    property bool shouldLoad: Math.abs(index - root.staticIdx) <= 3
                    scale:   active ? 1.10 : 0.80
                    opacity: active ? 1.0 : 0.50
                    Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 280 } }
                    Rectangle {
                        anchors.fill: parent; radius: 12; color: "#111"; clip: true
                        antialiasing: true
                        Image {
                            anchors.fill: parent
                            source: sDelegate.shouldLoad ? "file://" + modelData : ""
                            fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: "transparent"
                            border.color: sDelegate.active ? Qt.rgba(1,1,1,0.65) : Qt.rgba(1,1,1,0.06)
                            border.width: sDelegate.active ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyStaticWall(index) }
                }
            }
        }

        // ── Live row ──
        Row {
            width: parent.width
            height: (parent.height - 8) / 2
            spacing: 8

            Text {
                text: "Live"
                color: root.activeRow === 1 ? "white" : Qt.rgba(1,1,1,0.35)
                font.pixelSize: 11; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter; width: 40
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            ListView {
                id: liveList
                width: parent.width - 48; height: parent.height
                orientation: ListView.Horizontal
                spacing: 8; clip: true
                model: root.liveWalls
                cacheBuffer: Math.max(0, Math.round(height * 16/9) * 3)
                property real cardW: Math.round(height * 16/9)
                currentIndex: root.liveIdx
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width/2 - cardW/2
                preferredHighlightEnd:   width/2 + cardW/2
                Behavior on contentX { SmoothedAnimation { duration: 300; easing.type: Easing.InOutCubic } }

                delegate: Item {
                    id: lDelegate
                    width: liveList.cardW; height: liveList.height
                    property bool active: index === root.liveIdx && root.activeRow === 1
                    property bool shouldLoad: Math.abs(index - root.liveIdx) <= 3
                    scale:   active ? 1.10 : 0.80
                    opacity: active ? 1.0 : 0.50
                    Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 280 } }
                    Rectangle {
                        anchors.fill: parent; radius: 12; color: "#111"; clip: true
                        antialiasing: true
                        Image {
                            anchors.fill: parent
                            source: lDelegate.shouldLoad && modelData.preview !== "" ? "file://" + modelData.preview : ""
                            fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: "transparent"
                            border.color: lDelegate.active ? Qt.rgba(1,1,1,0.65) : Qt.rgba(1,1,1,0.06)
                            border.width: lDelegate.active ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyLiveWall(index) }
                }
            }
        }
    }
}
