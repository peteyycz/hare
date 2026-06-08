import QtQuick
import "../Theme"

// .barbtn chrome: pill-ish rounded hit area that fills on hover. Children are
// laid out in a centered row.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int hpad: 9
    // sticky highlight, e.g. while the button's popup is open
    property bool active: false
    signal clicked
    signal rightClicked

    implicitWidth: row.implicitWidth + hpad * 2
    implicitHeight: Theme.barHeight - 12
    radius: Theme.rSm
    color: (mouse.containsMouse || active) ? Theme.fill : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
