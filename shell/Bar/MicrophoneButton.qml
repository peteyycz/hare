import QtQuick
import Quickshell.Services.Pipewire
import "../Common"

// Microphone mute. Icon reflects mute state; click toggles the default input.
BarButton {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? false

    onClicked: if (source?.audio)
        source.audio.muted = !source.audio.muted

    PwObjectTracker {
        objects: [root.source]
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        // fixed box + centered glyph so the button doesn't reflow when the
        // mute/unmute glyphs (different widths) swap
        width: 18
        horizontalAlignment: Text.AlignHCenter
        code: root.muted ? 0xf131 : 0xf130 // microphone-slash / microphone
        opacity: root.muted ? 0.5 : 1.0
    }
}
