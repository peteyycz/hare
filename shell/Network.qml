import QtQuick

// Bar wifi button → toggles the Network panel. Mirrors the ControlCenter /
// NotifButton pattern: owns an `open` state the bar wires to NetworkPanel and
// stays highlighted while open. Dims when no active connection so the user
// can tell at a glance.
BarButton {
    id: root

    property bool open: false
    active: open

    onClicked: root.open = !root.open

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf1eb // nf-fa-wifi
        opacity: Networks.wifiEnabled ? (Networks.activeSsid !== "" ? 1.0 : 0.55) : 0.35
    }
}
