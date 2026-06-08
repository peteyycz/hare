import QtQuick
import Quickshell.Hyprland
import "../Theme"

// Numbered workspace pills. Occupied workspaces get a faint fill; the focused
// one becomes a wide accent pill.
Row {
    id: root
    spacing: 5

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property bool active: Hyprland.focusedWorkspace?.id === modelData.id
            readonly property bool occupied: (modelData.lastIpcObject?.windows ?? 0) > 0

            implicitWidth: active ? 34 : 22
            implicitHeight: 22
            radius: Theme.rSm
            color: active ? Theme.accent : (occupied ? Theme.fill : "transparent")

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.modelData.id
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: pill.active ? Theme.accentInk : (pill.occupied ? Theme.textDim : Theme.textFaint)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + pill.modelData.id)
            }
        }
    }
}
