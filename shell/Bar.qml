import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Liquid-glass top bar. Quickshell renders the translucent fill + specular
// highlight; the compositor (Hyprland `layerrule blur, namespace:hare`) adds
// the blur behind it.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    // game mode forces the full-width, square, flush-to-top bar (no floating
    // inset/rounding) to match the stripped-down compositor look
    readonly property bool full: Theme.barStyle === "full" || GameMode.enabled
    readonly property int inset: full ? 0 : 8

    WlrLayershell.namespace: "hare"
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + inset
    exclusiveZone: implicitHeight

    Rectangle {
        id: glass

        anchors.fill: parent
        anchors.topMargin: bar.inset
        anchors.leftMargin: bar.inset
        anchors.rightMargin: bar.inset

        radius: bar.full ? 0 : Theme.rMd + 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        clip: true

        // soft top specular glow (the liquid-glass sheen)
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: parent.height * 0.6
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        // bright 1px top edge highlight
        Rectangle {
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

        // ---- left segment ----
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }
            VLine {}
            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ---- center clock ----
        Clock {
            anchors.centerIn: parent
        }

        // ---- right segment ----
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Media {
                Layout.alignment: Qt.AlignVCenter
            }
            VLine {}
            SysTray {
                Layout.alignment: Qt.AlignVCenter
            }
            Microphone {
                Layout.alignment: Qt.AlignVCenter
            }
            Battery {
                Layout.alignment: Qt.AlignVCenter
            }
            NotifButton {
                id: notifButton
                Layout.alignment: Qt.AlignVCenter
                // the two top-right popups share a slot — opening one closes the other
                onOpenChanged: if (open)
                    controlCenter.open = false
            }
            ControlCenter {
                id: controlCenter
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open)
                    notifButton.open = false
            }
            Power {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Top-right popups — each its own layer-shell surface anchored under the bar.
    ControlCenterPanel {
        screen: bar.screen
        open: controlCenter.open
    }
    NotificationCenterPanel {
        screen: bar.screen
        open: notifButton.open
    }
}
