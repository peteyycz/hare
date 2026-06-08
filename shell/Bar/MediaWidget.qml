import QtQuick
import Quickshell.Services.Mpris
import "../Theme"

// Now-playing: animated EQ bars + "Artist — Title". Click toggles play/pause.
BarButton {
    id: root

    readonly property var player: {
        const ps = Mpris.players?.values ?? [];
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }
    readonly property bool playing: player?.isPlaying ?? false

    function truncate(s, n) {
        return s.length > n ? s.slice(0, n - 1) + "…" : s;
    }

    visible: player !== null
    onClicked: if (player)
        player.togglePlaying()

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 17
        height: 13

        Row {
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: 4

                Rectangle {
                    required property int index
                    width: 2
                    radius: 1
                    anchors.bottom: parent.bottom
                    height: 4
                    color: Theme.accent

                    SequentialAnimation on height {
                        running: root.playing
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 13
                            duration: 380 + index * 90
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 4
                            duration: 380 + index * 90
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.player ? root.truncate((root.player.trackArtist ? root.player.trackArtist + " — " : "") + (root.player.trackTitle ?? ""), 28) : ""
        font.family: Theme.fonts.sans
        font.pixelSize: 13
        color: Theme.textDim
    }
}
