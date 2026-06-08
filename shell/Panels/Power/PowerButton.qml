import QtQuick
import Quickshell.Io
import "../../Common"
import "../../Bar"

// Power button → wlogout.
BarButton {
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf011 // nf-fa-power_off
    }
    onClicked: wlogout.running = true

    Process {
        id: wlogout
        command: ["wlogout"]
    }
}
