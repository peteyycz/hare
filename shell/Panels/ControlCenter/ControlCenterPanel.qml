import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../../Theme"
import "../../Common"
import "../../Services"

// Liquid-glass Control Center — the design's `#control` popup. A separate
// layer-shell surface (namespace "hare", so the Hyprland blur rule applies)
// anchored under the bar at the top-right. Toggled by the control-center bar
// button. Quick toggles, brightness + volume sliders, and a now-playing card.
PanelWindow {
    id: panel

    property bool open: false

    visible: open
    color: "transparent"

    WlrLayershell.namespace: "hare"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        right: true
    }
    margins {
        // Shared top-right popup placement (see Theme). The bar's exclusive zone
        // already offsets us below it; this is just the gap + edge inset.
        top: Theme.popupGap
        right: Theme.popupEdge
    }
    exclusiveZone: 0

    implicitWidth: 372
    implicitHeight: col.implicitHeight + Theme.pad * 2

    // ---- live sources ----
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property MprisPlayer player: {
        const ps = Mpris.players?.values ?? [];
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }
    property real brightness: 0.72   // cosmetic default; applied via brightnessctl
    // brightnessctl only controls an internal backlight (laptops); desktops /
    // external-only setups have none, so the Display slider is hidden there.
    property bool hasBacklight: false

    Process {
        id: backlightQuery
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: panel.hasBacklight = text.trim().length > 0
        }
    }

    PwObjectTracker {
        objects: [panel.sink]
    }

    // keep the media progress ticking while playing
    property real mediaPos: 0
    Timer {
        interval: 1000
        repeat: true
        running: panel.visible && (panel.player?.isPlaying ?? false)
        triggeredOnStart: true
        onTriggered: panel.mediaPos = panel.player?.position ?? 0
    }

    Process {
        id: brightnessProc
    }
    function applyBrightness(v) {
        panel.brightness = v;
        brightnessProc.command = ["sh", "-c", "brightnessctl set " + Math.round(v * 100) + "% || true"];
        brightnessProc.running = true;
    }

    function fmtTime(secs) {
        if (!secs || secs < 0 || !isFinite(secs))
            return "0:00";
        const m = Math.floor(secs / 60);
        const s = Math.floor(secs % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ============================================================
    //  Toggle backends
    // ============================================================

    // ---- Focus / Do-Not-Disturb (drives the notification server's `dnd`) ----
    // State lives in the Notifs singleton so it's shared across screens and the
    // server can read it; the toggle below is just a view onto it.

    // ---- Night Light (hyprsunset daemon, alive while the toggle is on) ----
    Process {
        id: nightProc
        command: ["hyprsunset", "-t", "3500"]
    }

    // ---- Caffeine (logind idle/sleep inhibitor, held while on) ----
    Process {
        id: caffeineProc
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=hare", "--why=Caffeine", "sleep", "infinity"]
    }

    // ---- Screen recorder (wf-recorder; SIGINT to finalize cleanly) ----
    property string recPath: ""
    Process {
        id: recProc
    }
    function toggleRecording() {
        if (recProc.running) {
            recProc.signal(2); // SIGINT — lets wf-recorder flush the file
            return;
        }
        const dir = (Quickshell.env("HOME") ?? "") + "/Videos";
        recPath = dir + "/hare-" + Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss") + ".mp4";
        recProc.command = ["sh", "-c", "mkdir -p \"$1\"; exec wf-recorder -f \"$2\" -c libx264 -p preset=fast -p crf=18 --pixel-format yuv420p", "sh", dir, recPath];
        recProc.running = true;
    }

    // ---- glass surface ----
    // ClippingRectangle (not a plain Rectangle + clip) so children are clipped
    // to the *rounded* shape — a plain `clip` only clips to the square bounds,
    // which left glitchy nubs where the sheen overran the rounded corners.
    ClippingRectangle {
        id: glass
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.bg
        // borderless glass, like the bar

        // entrance animation (pop-in)
        opacity: 0
        transform: Scale {
            id: popScale
            origin.x: glass.width
            origin.y: 0
            xScale: 0.97
            yScale: 0.97
        }
        states: State {
            name: "shown"
            when: panel.visible
            PropertyChanges {
                target: glass
                opacity: 1
            }
            PropertyChanges {
                target: popScale
                xScale: 1
                yScale: 1
            }
        }
        transitions: Transition {
            NumberAnimation {
                properties: "opacity,xScale,yScale"
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap

            // ---- quick toggles ----
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Theme.gap
                columnSpacing: Theme.gap

                Toggle {
                    icon: 0xf05b // crosshairs
                    name: "Game Mode"
                    on: GameModeService.enabled
                    status: GameModeService.enabled ? "On" : "Off"
                    onToggled: GameModeService.enabled = !GameModeService.enabled
                }
                Toggle {
                    icon: 0xf186 // moon (do-not-disturb)
                    name: "Focus"
                    on: NotificationService.dnd
                    status: NotificationService.dnd ? "On" : "Off"
                    onToggled: NotificationService.dnd = !NotificationService.dnd
                }
                Toggle {
                    icon: 0xf0eb // night light (lightbulb)
                    name: "Night Light"
                    on: nightProc.running
                    status: nightProc.running ? "3500K" : "Off"
                    onToggled: nightProc.running = !nightProc.running
                }
                Toggle {
                    icon: 0xf0f4 // caffeine (coffee)
                    name: "Caffeine"
                    on: caffeineProc.running
                    status: caffeineProc.running ? "Awake" : "Off"
                    onToggled: caffeineProc.running = !caffeineProc.running
                }
                Toggle {
                    icon: 0xf03d // screen recorder (video camera)
                    name: "Record"
                    on: recProc.running
                    status: recProc.running ? "Recording" : "Off"
                    onToggled: panel.toggleRecording()
                }
            }

            // ---- brightness (only when an internal backlight exists) ----
            SliderRow {
                Layout.fillWidth: true
                visible: panel.hasBacklight
                heading: "Display"
                glyph: 0xf185 // sun
                value: panel.brightness
                onMoved: v => panel.applyBrightness(v)
            }

            // ---- volume ----
            SliderRow {
                Layout.fillWidth: true
                heading: "Sound — " + (panel.sink?.description ?? "Built-in")
                glyph: 0xf028 // volume
                value: panel.sink?.audio?.volume ?? 0
                onMoved: v => {
                    if (panel.sink?.audio)
                        panel.sink.audio.volume = v;
                }
            }

            // ---- now playing ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mediaCol.implicitHeight + 28
                radius: Theme.rMd
                color: Theme.fill
                border.width: 1
                border.color: Theme.hairline
                visible: panel.player !== null

                ColumnLayout {
                    id: mediaCol
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    anchors.topMargin: 14
                    anchors.bottomMargin: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 13

                        Rectangle {
                            implicitWidth: 52
                            implicitHeight: 52
                            radius: Theme.rSm
                            clip: true
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: Theme.accent
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.darker(Theme.accent, 1.6)
                                }
                            }

                            Icon {
                                anchors.centerIn: parent
                                code: 0xf001 // music
                                size: 22
                                color: Theme.accentInk
                                visible: art.status !== Image.Ready
                            }
                            Image {
                                id: art
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: panel.player?.trackArtUrl ?? ""
                                cache: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: panel.player?.trackTitle ?? "—"
                                font.family: Theme.fonts.sans
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: Theme.text
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const a = panel.player?.trackArtist ?? "";
                                    const al = panel.player?.trackAlbum ?? "";
                                    return [a, al].filter(Boolean).join(" · ");
                                }
                                font.family: Theme.fonts.sans
                                font.pixelSize: 12
                                color: Theme.textDim
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // progress
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.fillStrong
                        clip: true

                        readonly property real frac: {
                            const len = panel.player?.length ?? 0;
                            return len > 0 ? Math.max(0, Math.min(1, panel.mediaPos / len)) : 0;
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * parent.frac
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: panel.fmtTime(panel.mediaPos)
                            font.family: Theme.fonts.mono
                            font.pixelSize: 11
                            color: Theme.textFaint
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: {
                                const len = panel.player?.length ?? 0;
                                return len > 0 ? "-" + panel.fmtTime(len - panel.mediaPos) : "";
                            }
                            font.family: Theme.fonts.mono
                            font.pixelSize: 11
                            color: Theme.textFaint
                        }
                    }

                    // transport controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 22

                        MediaButton {
                            code: 0xf048 // skip-back
                            size: 18
                            onClicked: panel.player?.previous()
                        }
                        MediaButton {
                            filled: true
                            code: (panel.player?.isPlaying ?? false) ? 0xf04c : 0xf04b // pause / play
                            size: 16
                            onClicked: panel.player?.togglePlaying()
                        }
                        MediaButton {
                            code: 0xf051 // skip-forward
                            size: 18
                            onClicked: panel.player?.next()
                        }
                    }
                }
            }
        }
    }
}
