import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Audio (output), microphone (input), and keyboard layout. Each piece is gated
// by the bar.status.* flags from config. Glyphs are Nerd Font codepoints.
RowLayout {
    id: root
    spacing: 12

    readonly property var status: Theme.bar.status ?? ({
            showAudio: true,
            showMicrophone: true,
            showKbLayout: true
        })

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    property string kbLayout: ""

    function shorten(name) {
        if (!name)
            return "";
        const m = name.match(/\(([^)]+)\)/);
        if (m)
            return m[1].slice(0, 2).toUpperCase();
        return name.slice(0, 2).toUpperCase();
    }

    // Keep the sink/source bound so their .audio properties stay live.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    component Glyph: Text {
        color: Theme.fg
        font.family: "Symbols Nerd Font"
        font.pixelSize: 14
        Layout.alignment: Qt.AlignVCenter
    }

    Glyph {
        visible: root.status.showAudio
        text: root.muted || root.volume === 0 ? "" : "" // volume-off / volume-up
        opacity: root.muted ? 0.45 : 1.0

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.sink.audio.muted;
            }
        }
    }

    Glyph {
        visible: root.status.showMicrophone
        text: root.micMuted ? "" : "" // microphone-slash / microphone
        opacity: root.micMuted ? 0.45 : 1.0

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.source?.audio)
                    root.source.audio.muted = !root.source.audio.muted;
            }
        }
    }

    Text {
        visible: root.status.showKbLayout && root.kbLayout !== ""
        text: root.kbLayout
        color: Theme.subtle
        font.family: Theme.fonts.sans
        font.pixelSize: 12
        font.weight: Font.Medium
        Layout.alignment: Qt.AlignVCenter
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const parts = event.data.split(",");
                root.kbLayout = root.shorten(parts[parts.length - 1]);
            }
        }
    }

    // Seed the current layout on startup (events only fire on change).
    Process {
        id: kbProc
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const kbs = data.keyboards ?? [];
                    const kb = kbs.find(k => k.main) ?? kbs[0];
                    if (kb)
                        root.kbLayout = root.shorten(kb.active_keymap);
                } catch (e) {}
            }
        }
    }
}
