import QtQuick
import Quickshell.Hyprland

// Workspace pills: the focused one stretches into a wide pill, the rest are
// dots. Click to switch.
Row {
    id: root
    spacing: 8

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property bool active: Hyprland.focusedWorkspace?.id === modelData.id

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: active ? 26 : 10
            implicitHeight: 10
            radius: height / 2
            color: active ? Theme.accent : Theme.subtle
            opacity: active ? 1.0 : 0.45

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + pill.modelData.id)
            }
        }
    }
}
