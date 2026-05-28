pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for the Liquid Glass look. Reads the user config
// (palettes + fonts) written by the home-manager module and the live tone file
// written by hare-tone, then exposes ready-to-use colours, fonts, and geometry.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/hare/config.json"
    readonly property string tonePath: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/hare/tone"

    property var config: ({})
    property string detectedTone: "light"

    readonly property string mode: config?.theme?.mode ?? "adaptive"
    readonly property string activeTone: mode === "adaptive" ? detectedTone : mode

    readonly property var fallback: ({
            dark: {
                bg: "18181c",
                bgAlpha: 0.46,
                surface: "27272a",
                ink: "ffffff",
                fillBase: "ffffff",
                fillAlpha: 0.08,
                fillStrongAlpha: 0.15,
                hairlineBase: "ffffff",
                hairlineAlpha: 0.10,
                border: "ffffff",
                borderAlpha: 0.14,
                hi: "ffffff",
                hiAlpha: 0.30,
                accent: "c4a8c4",
                accentInk: "16121a",
                error: "e0533f"
            },
            light: {
                bg: "f8f9fb",
                bgAlpha: 0.55,
                surface: "e9ecf2",
                ink: "1c1f27",
                fillBase: "464e62",
                fillAlpha: 0.10,
                fillStrongAlpha: 0.18,
                hairlineBase: "283042",
                hairlineAlpha: 0.12,
                border: "ffffff",
                borderAlpha: 0.65,
                hi: "ffffff",
                hiAlpha: 0.95,
                accent: "c4a8c4",
                accentInk: "ffffff",
                error: "e0533f"
            }
        })

    readonly property var p: config?.theme?.palette?.[activeTone] ?? fallback[activeTone]
    readonly property var fonts: config?.theme?.fonts ?? ({
            sans: "sans-serif",
            mono: "monospace"
        })
    readonly property var barCfg: config?.bar ?? ({
            height: 36,
            style: "floating"
        })

    function rgba(hex, a) {
        return Qt.rgba(parseInt(hex.substr(0, 2), 16) / 255, parseInt(hex.substr(2, 2), 16) / 255, parseInt(hex.substr(4, 2), 16) / 255, a);
    }

    // ---- colours ----
    readonly property color bg: rgba(p.bg, p.bgAlpha)
    readonly property color text: rgba(p.ink, 0.92)
    readonly property color textDim: rgba(p.ink, 0.56)
    readonly property color textFaint: rgba(p.ink, 0.34)
    readonly property color fill: rgba(p.fillBase, p.fillAlpha)
    readonly property color fillStrong: rgba(p.fillBase, p.fillStrongAlpha)
    readonly property color hairline: rgba(p.hairlineBase, p.hairlineAlpha)
    readonly property color border: rgba(p.border, p.borderAlpha)
    readonly property color hi: rgba(p.hi, p.hiAlpha)
    readonly property color accent: "#" + p.accent
    readonly property color accentInk: "#" + p.accentInk
    readonly property color error: "#" + p.error

    // opaque base of the glass material (for elements that sit *on* a panel,
    // e.g. the media play-button icon punched out of the surface).
    readonly property color bgSolid: rgba(p.bg, 1)

    // ---- geometry (medium corners) ----
    readonly property int rLg: 16
    readonly property int rMd: 12
    readonly property int rSm: 8
    readonly property int rPill: 999
    readonly property int barHeight: barCfg.height ?? 36
    readonly property string barStyle: barCfg.style ?? "floating"
    readonly property int gap: 11
    readonly property int pad: 14

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
