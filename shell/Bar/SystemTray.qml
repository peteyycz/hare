import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../Theme"

// System tray (StatusNotifierItem). Left click activates, right click triggers
// the secondary action.
Row {
    id: root
    spacing: 3

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: item
            required property var modelData

            width: 28
            height: 28
            radius: Theme.rSm
            color: mouse.containsMouse ? Theme.fill : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: item.modelData.icon
                opacity: mouse.containsMouse ? 1.0 : 0.82
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: e => {
                    if (e.button === Qt.LeftButton)
                        item.modelData.activate();
                    else
                        item.modelData.secondaryActivate();
                }
            }
        }
    }
}
