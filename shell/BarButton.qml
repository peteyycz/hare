import QtQuick

// .barbtn chrome: pill-ish rounded hit area that fills on hover. Children are
// laid out in a centered row.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int hpad: 9
    signal clicked
    signal rightClicked

    implicitWidth: row.implicitWidth + hpad * 2
    implicitHeight: Theme.barHeight - 12
    radius: Theme.rSm
    color: mouse.containsMouse ? Theme.fill : "transparent"

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
