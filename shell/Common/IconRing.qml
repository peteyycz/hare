import QtQuick
import QtQuick.Layouts
import "../Theme"

// 36px circular icon ring used by row tiles (Toggle, WifiItem, BluetoothItem,
// EthernetItem, VpnItem). Brightens to a translucent white when the parent
// row is `selected` (accent state); otherwise sits at `fillStrong`.
Rectangle {
    id: root

    property int code: 0
    property bool selected: false
    property int size: 36
    property int iconSize: 17
    property real iconOpacity: 1.0

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: selected ? Theme.rgba("ffffff", 0.22) : Theme.fillStrong

    Icon {
        anchors.centerIn: parent
        code: root.code
        size: root.iconSize
        color: root.selected ? Theme.accentInk : Theme.text
        opacity: root.iconOpacity
    }
}
