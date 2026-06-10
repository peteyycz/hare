import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../Theme"
import "../Common"
import "../Services"
import "../Panels/ControlCenter"
import "../Panels/Network"
import "../Panels/Bluetooth"
import "../Panels/Battery"
import "../Panels/Notifications"
import "../Panels/Power"

// Liquid-glass top bar. Quickshell renders the translucent fill + specular
// highlight; the compositor (Hyprland `layerrule blur, namespace:hare`) adds
// the blur behind it.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    // game mode forces the full-width, square, flush-to-top bar (no floating
    // inset/rounding) to match the stripped-down compositor look
    readonly property bool notched: Theme.barStyle === "notched" && !GameModeService.enabled
    // edge-to-edge (square, flush) covers both "full" and "notched"
    readonly property bool edge: Theme.barStyle === "full" || notched || GameModeService.enabled
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
            Separator {}
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

            MediaWidget {
                Layout.alignment: Qt.AlignVCenter
            }
            Separator {}
            SystemTray {
                Layout.alignment: Qt.AlignVCenter
            }
            MicrophoneButton {
                Layout.alignment: Qt.AlignVCenter
            }
            BatteryButton {
                id: batteryButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    notificationButton.open = false;
                    controlCenterButton.open = false;
                    powerButton.open = false;
                }
            }
            NetworkButton {
                id: networkButton
                Layout.alignment: Qt.AlignVCenter
                // the top-right popups share a slot — opening one closes the others
                onOpenChanged: if (open) {
                    batteryButton.open = false;
                    bluetoothButton.open = false;
                    notificationButton.open = false;
                    controlCenterButton.open = false;
                    powerButton.open = false;
                }
            }
            BluetoothButton {
                id: bluetoothButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    batteryButton.open = false;
                    networkButton.open = false;
                    notificationButton.open = false;
                    controlCenterButton.open = false;
                    powerButton.open = false;
                }
            }
            NotificationButton {
                id: notificationButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    batteryButton.open = false;
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    controlCenterButton.open = false;
                    powerButton.open = false;
                }
            }
            ControlCenterButton {
                id: controlCenterButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    batteryButton.open = false;
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    notificationButton.open = false;
                    powerButton.open = false;
                }
            }
            PowerButton {
                id: powerButton
                Layout.alignment: Qt.AlignVCenter
                onOpenChanged: if (open) {
                    batteryButton.open = false;
                    networkButton.open = false;
                    bluetoothButton.open = false;
                    notificationButton.open = false;
                    controlCenterButton.open = false;
                }
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
        open: controlCenterButton.open
    }
    NotificationCenterPanel {
        id: notifPanel
        screen: bar.screen
        open: notificationButton.open
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
        open: batteryButton.open
        onClose: batteryButton.open = false
    }
    PowerPanel {
        id: powerPanel
        screen: bar.screen
        open: powerButton.open
        onClose: powerButton.open = false
    }

    // Click-outside-to-close. While a popup is open, Hyprland grabs input for
    // these surfaces only: clicks inside the panel work normally, and the first
    // click anywhere outside fires `cleared`, which closes the open popup.
    HyprlandFocusGrab {
        active: controlCenterButton.open || notificationButton.open || networkButton.open || bluetoothButton.open || batteryButton.open || powerButton.open
        windows: [ccPanel, notifPanel, networkPanel, btPanel, battPanel, powerPanel]
        onCleared: {
            controlCenterButton.open = false;
            notificationButton.open = false;
            networkButton.open = false;
            bluetoothButton.open = false;
            batteryButton.open = false;
            powerButton.open = false;
        }
    }
}
