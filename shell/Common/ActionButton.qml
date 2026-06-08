import QtQuick
import "../Theme"

// Pill action button used inside expanded item rows (Connect / Disconnect /
// Pair). When the owning row is `selected` (accent fill), the button paints
// in inverted translucent-white over the accent; otherwise it sits on the
// row's fillStrong and brightens to accent on hover.
Rectangle {
    id: root

    property string text: ""
    property bool selected: false   // mirror parent row's accent state
    property bool busy: false
    property bool enabled: true
    signal clicked

    implicitHeight: 32
    implicitWidth: label.implicitWidth + 26
    radius: Theme.rSm
    color: {
        if (selected)
            return mouse.containsMouse ? Theme.rgba("ffffff", 0.32) : Theme.rgba("ffffff", 0.18);
        return mouse.containsMouse ? Theme.accent : Theme.fillStrong;
    }
    border.width: 1
    border.color: selected ? "transparent" : (mouse.containsMouse ? "transparent" : Theme.hairline)

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.busy ? "…" : root.text
        font.family: Theme.fonts.sans
        font.pixelSize: 12
        font.weight: Font.Medium
        color: root.selected ? Theme.accentInk : (mouse.containsMouse ? Theme.accentInk : Theme.text)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
