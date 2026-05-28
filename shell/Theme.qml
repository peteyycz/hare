pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for the glass look. Reads the user config written by
// the home-manager module and the live "tone" file written by hare-tone, then
// exposes ready-to-use colours/fonts for the rest of the shell.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/hare/config.json"
    readonly property string tonePath: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/hare/tone"

    property var config: ({})
    property string detectedTone: "dark"

    readonly property string mode: config?.theme?.mode ?? "adaptive"
    readonly property string activeTone: mode === "adaptive" ? detectedTone : mode

    readonly property var fallback: ({
            dark: {
                bg: "18181b",
                surface: "27272a",
                fg: "f4f4f5",
                subtle: "a1a1aa",
                accent: "e4e4e7",
                error: "f87171",
                border: "ffffff",
                bgAlpha: 0.55,
                borderAlpha: 0.10
            },
            light: {
                bg: "fafafa",
                surface: "f4f4f5",
                fg: "18181b",
                subtle: "52525b",
                accent: "3f3f46",
                error: "dc2626",
                border: "ffffff",
                bgAlpha: 0.6,
                borderAlpha: 0.55
            }
        })

    readonly property var palette: config?.theme?.palette?.[activeTone] ?? fallback[activeTone]
    readonly property var fonts: config?.theme?.fonts ?? ({
            sans: "sans-serif",
            mono: "monospace"
        })
    readonly property var bar: config?.bar ?? ({
            height: 36,
            entries: ["workspaces", "spacer", "tray", "statusIcons", "clock", "power"],
            status: {
                showAudio: true,
                showMicrophone: true,
                showKbLayout: true
            }
        })

    function rgba(hex, a) {
        return Qt.rgba(parseInt(hex.substr(0, 2), 16) / 255, parseInt(hex.substr(2, 2), 16) / 255, parseInt(hex.substr(4, 2), 16) / 255, a);
    }

    readonly property color bg: rgba(palette.bg, palette.bgAlpha)
    readonly property color surface: rgba(palette.surface, 0.5)
    readonly property color fg: "#" + palette.fg
    readonly property color subtle: "#" + palette.subtle
    readonly property color accent: "#" + palette.accent
    readonly property color error: "#" + palette.error
    readonly property color border: rgba(palette.border, palette.borderAlpha)

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.config = JSON.parse(text());
            } catch (e) {
                console.warn("hare: could not parse config.json:", e);
            }
        }
    }

    FileView {
        path: root.tonePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = text().trim();
            if (t === "dark" || t === "light")
                root.detectedTone = t;
        }
    }
}
