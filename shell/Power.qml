import QtQuick
import Quickshell.Io

Text {
    id: root

    text: "" // nf-fa-power_off
    color: Theme.fg
    font.family: "Symbols Nerd Font"
    font.pixelSize: 15

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: wlogout.running = true
    }

    Process {
        id: wlogout
        command: ["wlogout"]
    }
}
