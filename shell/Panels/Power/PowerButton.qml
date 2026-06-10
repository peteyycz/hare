import QtQuick
import "../../Common"
import "../../Bar"

// Power-menu toggle. Owns an `open` state that the bar wires to the PowerPanel
// popup; the button stays highlighted while it's open.
BarButton {
    id: root

    property bool open: false
    active: open
    onClicked: root.open = !root.open

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf011 // nf-fa-power_off
    }
}
