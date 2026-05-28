import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// System tray (StatusNotifierItem). Left click activates, right click triggers
// the item's secondary action.
RowLayout {
    id: root
    spacing: 12

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item
            required property var modelData

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.LeftButton)
                    modelData.activate();
                else
                    modelData.secondaryActivate();
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
