import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// A floating, frosted top bar. Quickshell renders the translucent fill; the
// compositor (e.g. a Hyprland `layerrule blur, namespace:hare`) supplies the
// blur that makes it read as glass.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property var entries: Theme.bar.entries ?? ["workspaces", "spacer", "tray", "statusIcons", "clock", "power"]

    WlrLayershell.namespace: "hare"
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.bar.height ?? 36
    exclusiveZone: implicitHeight

    function componentFor(name) {
        switch (name) {
        case "workspaces":
            return cWorkspaces;
        case "tray":
            return cTray;
        case "statusIcons":
            return cStatus;
        case "clock":
            return cClock;
        case "power":
            return cPower;
        default:
            return null;
        }
    }

    Component {
        id: cWorkspaces
        Workspaces {}
    }
    Component {
        id: cTray
        SysTray {}
    }
    Component {
        id: cStatus
        StatusIcons {}
    }
    Component {
        id: cClock
        Clock {}
    }
    Component {
        id: cPower
        Power {}
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: 14
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Repeater {
                model: bar.entries

                delegate: Loader {
                    required property var modelData
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: modelData === "spacer"
                    sourceComponent: bar.componentFor(modelData)
                }
            }
        }
    }
}
