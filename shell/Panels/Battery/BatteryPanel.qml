import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Theme"
import "../../Common"
import "../../Services"

// Battery / power-profile chooser. A tighter cousin of the other top-right
// popups — three Toggle rows, one per power-profiles-daemon profile, with
// the active one painted in the accent. Selecting a profile dispatches via
// `powerprofilesctl set` and emits `close` so the bar button can drop its
// open state.
//
// Each row is gated on PowerProfileService.profiles so we don't show options
// the installed daemon doesn't actually advertise (e.g. systems without
// platform_profile only expose "balanced" + "power-saver").
PanelWindow {
    id: panel

    property bool open: false
    signal close

    visible: open
    color: "transparent"

    WlrLayershell.namespace: "hare"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.popupGap
        right: Theme.popupEdge
    }
    exclusiveZone: 0

    implicitWidth: 280
    implicitHeight: col.implicitHeight + Theme.pad * 2

    ClippingRectangle {
        id: glass
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.bg

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

            Text {
                text: "Power Mode"
                font.family: Theme.fonts.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.text
            }

            Toggle {
                icon: 0xf135 // rocket
                name: "Performance"
                status: "Maximum performance"
                on: PowerProfileService.active === "performance"
                visible: PowerProfileService.has("performance")
                onToggled: {
                    PowerProfileService.set("performance");
                    panel.close();
                }
            }

            Toggle {
                icon: 0xf24e // balance-scale
                name: "Balanced"
                status: "Default mode"
                on: PowerProfileService.active === "balanced"
                visible: PowerProfileService.has("balanced")
                onToggled: {
                    PowerProfileService.set("balanced");
                    panel.close();
                }
            }

            Toggle {
                icon: 0xf06c // leaf
                name: "Power Saver"
                status: "Reduce power use"
                on: PowerProfileService.active === "power-saver"
                visible: PowerProfileService.has("power-saver")
                onToggled: {
                    PowerProfileService.set("power-saver");
                    panel.close();
                }
            }
        }
    }
}
