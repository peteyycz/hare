pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for the Liquid Glass look. Reads the user config
// (palette + fonts) written by the home-manager module and exposes ready-to-use
// colours, fonts, and geometry. Dark-only.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/hare/config.json"

    property var config: ({})

    readonly property var fallback: ({
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
            accent: "c4a8c4",
            accentInk: "16121a",
            error: "e0533f"
        })

    readonly property var p: {
        const palette = config?.theme?.palette;
        return (palette && typeof palette.bg === "string") ? palette : fallback;
    }
    readonly property var fonts: config?.theme?.fonts ?? ({
            sans: "sans-serif",
            mono: "monospace"
        })
    readonly property var barCfg: config?.bar ?? ({
            height: 36,
            style: "notched"
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
    readonly property string barStyle: barCfg.style ?? "notched"
    readonly property int gap: 11
    readonly property int pad: 14

    // ---- motion ----
    // Material 3 "emphasized" easing — accelerates out fast, then settles with a
    // long graceful tail. This is the signature buttery glide (the same feel
    // caelestia uses for fills/sliders/transitions). Use as:
    //   easing.type: Easing.BezierSpline
    //   easing.bezierCurve: Theme.emphasized
    readonly property var emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
    readonly property int durFast: 200
    readonly property int durNormal: 350
    readonly property int durSlow: 500

    // Placement for top-right popups (control center, notifications, …). The bar
    // reserves an exclusive zone, so popups only need the gap below it + the
    // inset from the screen edge. Reuse these for any future popup.
    readonly property int popupGap: 8    // top margin (gap under the bar)
    readonly property int popupEdge: 12  // right margin (inset from screen edge)

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
}
