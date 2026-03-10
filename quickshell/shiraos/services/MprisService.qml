import QtQuick
import Quickshell.Services.Mpris

// Item em vez de QtObject — aceita Timer como filho
Item {
    id: root
    visible: false

    property var player: {
        var list = Mpris.players.values
        if (!list || list.length === 0) return null
        for (var i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list[0]
    }

    property bool   hasPlayer: player !== null
    property string title:     player ? (player.trackTitle  || "") : ""
    property string artist:    player ? (player.trackArtist || "") : ""
    property string albumArt:  player ? (player.trackArtUrl || "") : ""
    property bool   playing:   player ? player.isPlaying : false
    property real   length:    player ? player.length    : 0
    property real   position:  0
    property real   progress:  length > 0 ? Math.min(position / length, 1.0) : 0

    onPlayerChanged: {
        position = player ? player.position : 0
    }

    Timer {
        interval: 1000
        repeat:   true
        running:  root.playing
        onTriggered: {
            if (root.player) root.position = root.player.position
        }
    }

    function playPause() { if (player) player.togglePlaying() }
    function next()      { if (player) player.next()          }
    function prev()      { if (player) player.previous()      }
}
