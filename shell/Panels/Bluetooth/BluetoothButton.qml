import QtQuick
import "../../Theme"
import "../../Common"
import "../../Services"
import "../../Bar"

// Bar bluetooth button → toggles the BluetoothPanel. Same pattern as
// NetworkButton / ControlCenterButton / NotificationButton — owns an `open`
// state the bar wires to the panel and stays highlighted while open. Icon
// dims when the adapter is off and brightens when at least one device is
// connected.
//
// Named BluetoothButton.qml (not Bluetooth.qml) so the local type doesn't
// collide with the `Bluetooth` singleton imported from Quickshell.Bluetooth.
BarButton {
    id: root

    property bool open: false
    active: open

    onClicked: root.open = !root.open

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf293 // nf-fa-bluetooth
        opacity: BluetoothService.enabled ? (BluetoothService.connectedDevices.length > 0 ? 1.0 : 0.55) : 0.35
    }
}
