import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../Theme"
import "../../Common"

// Volume OSD — the transient "liquid glass" pill that flashes near the bottom of
// the screen whenever the output volume (or mute) changes, e.g. via the media
// keys. Port of the handoff `OSD.html` component: a glass capsule holding an
// icon, a fixed-width progress track with a solid accent fill, and a numeric
// 0–100 readout, popping in with a scale+rise and auto-hiding after ~1.5s.
//
// Its own layer-shell surface (namespace "hare", so the Hyprland blur applies),
// horizontally centred by the compositor since only the bottom edge is anchored.
PanelWindow {
    id: osd

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // armed shortly after startup so the initial Pipewire binding doesn't flash
    // the OSD on launch
    property bool ready: false
    // drives the show/hide; `visible` lingers until the fade-out finishes
    property bool shown: false

    visible: shown || card.opacity > 0
    color: "transparent"

    WlrLayershell.namespace: "hare"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        bottom: true
    }
    margins {
        bottom: 96   // .osd--anchored { bottom: 96px }
    }
    exclusiveZone: 0

    // sized to the content: padding 16/22 around a 26 icon + 16 gap + 200 track
    // + 16 gap + 38 value box.
    implicitWidth: row.implicitWidth + 2 * 22
    implicitHeight: row.implicitHeight + 2 * 16

    PwObjectTracker {
        objects: [osd.sink]
    }

    Timer {
        id: arm
        interval: 800
        running: true
        repeat: false
        onTriggered: osd.ready = true
    }
    Timer {
        id: hide
        interval: 1500   // ~1.5s auto-hide after the last change
        repeat: false
        onTriggered: osd.shown = false
    }

    function flash() {
        if (!ready)
            return;
        shown = true;
        hide.restart();
    }
    onVolumeChanged: flash()
    onMutedChanged: flash()

    // ---- glass pill (the `.osd.glass` surface) ----
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.rPill   // clamps to height/2 → a capsule
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        antialiasing: true

        // entrance/exit "pop": fade + a small rise + slight scale, replayed on
        // show. (osd-pop: opacity 0→1, translateY 8→0, scale 0.96→1.)
        opacity: osd.shown ? 1 : 0
        scale: osd.shown ? 1 : 0.96
        transform: Translate {
            y: osd.shown ? 0 : 8
            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuint
                }
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            spacing: 16

            // modality icon — mute / low / high (mirrors the bar Volume button).
            // OSD.html maps volume-x / volume-1 (<50) / volume-2 (≥50).
            Icon {
                Layout.alignment: Qt.AlignVCenter
                // fixed box + centred glyph so the row doesn't shift when the
                // glyph swaps between mute/low/high
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignHCenter
                size: 20
                code: osd.muted ? 0xf026 : (osd.volume < 0.5 ? 0xf027 : 0xf028)
                opacity: osd.muted ? 0.5 : 1.0
            }

            // progress track — fixed 200×8 pill, solid accent fill
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 8
                radius: 4
                color: Theme.fillStrong
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width * Math.max(0, Math.min(1, osd.volume))
                    radius: parent.radius
                    visible: !osd.muted && width > 0
                    color: Theme.accent

                    // super-smooth fill glide — Material 3 "emphasized" curve,
                    // the buttery caelestia-style settle.
                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.durSlow
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                }
            }

            // numeric readout (0–100). `.val`: 15px DemiBold, fixed 38 box,
            // right-aligned so the track doesn't reflow as the number changes.
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: osd.muted ? "—" : Math.round(osd.volume * 100)
                font.family: Theme.fonts.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.text
            }
        }
    }
}
