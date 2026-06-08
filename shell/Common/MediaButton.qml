import QtQuick
import "../Theme"

// A transport-control button for the media card. Plain glyph by default; when
// `filled` it becomes the solid play/pause disc (the design's `.play`: an inked
// circle with the glyph punched out in the panel's base colour).
Rectangle {
    id: root

    property int code: 0
    property int size: 18
    property bool filled: false
    signal clicked

    implicitWidth: filled ? 42 : 34
    implicitHeight: filled ? 42 : 34
    radius: width / 2
    color: filled ? Theme.text : (mouse.containsMouse ? Theme.fill : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Icon {
        anchors.centerIn: parent
        code: root.code
        size: root.size
        color: root.filled ? Theme.bgSolid : Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
