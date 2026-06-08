import QtQuick
import Quickshell.Services.Pipewire
import "../../Common"
import "../../Bar"

// Output volume. Icon reflects mute/level; click toggles mute.
BarButton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    onClicked: if (sink?.audio)
        sink.audio.muted = !sink.audio.muted

    PwObjectTracker {
        objects: [root.sink]
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        // fixed box + centered glyph so the button doesn't reflow when the
        // volume/mute glyphs (different widths) swap
        width: 18
        horizontalAlignment: Text.AlignHCenter
        code: root.muted ? 0xf026 : (root.volume < 0.5 ? 0xf027 : 0xf028)
        opacity: root.muted ? 0.5 : 1.0
    }
}
