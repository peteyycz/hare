import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Liquid-glass top bar. Quickshell renders the translucent fill + specular
// highlight; the compositor (Hyprland `layerrule blur, namespace:hare`) adds
// the blur behind it.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    // game mode forces the full-width, square, flush-to-top bar (no floating
    // inset/rounding) to match the stripped-down compositor look
    readonly property bool notched: Theme.barStyle === "notched" && !GameMode.enabled
    // edge-to-edge (square, flush) covers both "full" and "notched"
    readonly property bool edge: Theme.barStyle === "full" || notched || GameMode.enabled
    readonly property int inset: edge ? 0 : 8
    // depth of the concave bottom-corner scoop (notched style only)
    readonly property int notch: 16

    WlrLayershell.namespace: "hare"
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }
    // the surface is tall enough to hold the corner fillets below the bar, but
    // only the bar itself reserves space — the scoops hang decoratively over
    // the area just under the bar.
    implicitHeight: Theme.barHeight + (notched ? notch : inset)
    exclusiveZone: Theme.barHeight + (edge ? 0 : inset)

    Rectangle {
        id: glass

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: bar.inset
        anchors.leftMargin: bar.inset
        anchors.rightMargin: bar.inset
        height: Theme.barHeight

        radius: bar.edge ? 0 : Theme.rMd + 2
        color: Theme.bg
        // notched is borderless (matches the design); floating/full keep the rim
        border.width: bar.notched ? 0 : 1
        border.color: Theme.border
        clip: true

        // ---- left segment ----
        // right edge stops before the centered clock so a very long window
        // title can't slide behind it; the title inside ActiveWindow elides
        // within whatever room is left.
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: clock.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }
            VLine {}
            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }

        // ---- center clock ----
        Clock {
            id: clock
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
                id: battery
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    notifButton.open = false;
                    controlCenter.open = false;
                }
            }
            Network {
                id: networkButton
                Layout.alignment: Qt.AlignVCenter
                // the top-right popups share a slot — opening one closes the others
                onOpenChanged: if (open) {
                    battery.open = false;
                    bluetoothButton.open = false;
                    notifButton.open = false;
                    controlCenter.open = false;
                }
            }
            BluetoothButton {
                id: bluetoothButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    battery.open = false;
                    networkButton.open = false;
                    notifButton.open = false;
                    controlCenter.open = false;
                }
            }
            NotifButton {
                id: notifButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    battery.open = false;
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    controlCenter.open = false;
                }
            }
            ControlCenter {
                id: controlCenter
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    battery.open = false;
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    notifButton.open = false;
                }
            }
            Power {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Notched style: concave glass scoops below the bar's bottom corners.
    BarCorner {
        visible: bar.notched
        side: "left"
        size: bar.notch
        color: Theme.bg
        anchors.top: glass.bottom
        anchors.left: glass.left
    }
    BarCorner {
        visible: bar.notched
        side: "right"
        size: bar.notch
        color: Theme.bg
        anchors.top: glass.bottom
        anchors.right: glass.right
    }

    // Top-right popups — each its own layer-shell surface anchored under the bar.
    ControlCenterPanel {
        id: ccPanel
        screen: bar.screen
        open: controlCenter.open
    }
    NotificationCenterPanel {
        id: notifPanel
        screen: bar.screen
        open: notifButton.open
    }
    NetworkPanel {
        id: networkPanel
        screen: bar.screen
        open: networkButton.open
    }
    BluetoothPanel {
        id: btPanel
        screen: bar.screen
        open: bluetoothButton.open
    }
    BatteryPanel {
        id: battPanel
        screen: bar.screen
        open: battery.open
        onClose: battery.open = false
    }

    // Click-outside-to-close. While a popup is open, Hyprland grabs input for
    // these surfaces only: clicks inside the panel work normally, and the first
    // click anywhere outside fires `cleared`, which closes the open popup.
    HyprlandFocusGrab {
        active: controlCenter.open || notifButton.open || networkButton.open || bluetoothButton.open || battery.open
        windows: [ccPanel, notifPanel, networkPanel, btPanel, battPanel]
        onCleared: {
            controlCenter.open = false;
            notifButton.open = false;
            networkButton.open = false;
            bluetoothButton.open = false;
            battery.open = false;
        }
    }
}
