import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Battery / power-profile chooser. A tighter cousin of the other top-right
// popups — three CcToggle rows, one per power-profiles-daemon profile, with
// the active one painted in the accent. Selecting a profile dispatches via
// `powerprofilesctl set` and emits `close` so the bar button can drop its
// open state.
//
// Each row is gated on PowerProfilesCtl.profiles so we don't show options the
// installed daemon doesn't actually advertise (e.g. systems without
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

        // top specular sheen — light theme only
        Rectangle {
            visible: Theme.activeTone === "light"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: parent.height * 0.4
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.10)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }
        Rectangle {
            visible: Theme.activeTone === "light"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.topMargin: 1
            anchors.leftMargin: glass.radius
            anchors.rightMargin: glass.radius
            height: 1
            color: Theme.hi
            opacity: 0.5
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

            CcToggle {
                icon: 0xf135 // rocket
                name: "Performance"
                status: "Maximum performance"
                on: PowerProfilesCtl.active === "performance"
                visible: PowerProfilesCtl.has("performance")
                onToggled: {
                    PowerProfilesCtl.set("performance");
                    panel.close();
                }
            }

            CcToggle {
                icon: 0xf24e // balance-scale
                name: "Balanced"
                status: "Default mode"
                on: PowerProfilesCtl.active === "balanced"
                visible: PowerProfilesCtl.has("balanced")
                onToggled: {
                    PowerProfilesCtl.set("balanced");
                    panel.close();
                }
            }

            CcToggle {
                icon: 0xf06c // leaf
                name: "Power Saver"
                status: "Reduce power use"
                on: PowerProfilesCtl.active === "power-saver"
                visible: PowerProfilesCtl.has("power-saver")
                onToggled: {
                    PowerProfilesCtl.set("power-saver");
                    panel.close();
                }
            }
        }
    }
}
