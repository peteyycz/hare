import QtQuick
import "../../Common"
import "../../Bar"

// Control-center toggle. Owns an `open` state that the bar wires to the
// ControlCenterPanel popup; the button stays highlighted while it's open.
BarButton {
    id: root

    property bool open: false
    active: open
    onClicked: root.open = !root.open

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf1de // nf-fa-sliders
    }
}
