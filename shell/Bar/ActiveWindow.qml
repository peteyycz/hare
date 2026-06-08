import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../Theme"

// Active window: accent glyph chip + app class (bold) + title (dim).
RowLayout {
    id: root
    spacing: 8

    readonly property var win: Hyprland.activeToplevel
    readonly property string appClass: win?.lastIpcObject?.class ?? ""
    readonly property string winTitle: win?.title ?? ""

    visible: appClass !== "" || winTitle !== ""

    function cap(s) {
        return s ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        width: 18
        height: 18
        radius: 5
        color: Theme.accent
        Text {
            anchors.centerIn: parent
            text: (root.appClass || "?").charAt(0).toUpperCase()
            font.family: Theme.fonts.sans
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.accentInk
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: 160
        text: root.cap(root.appClass)
        font.family: Theme.fonts.sans
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: Theme.text
        elide: Text.ElideRight
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        visible: root.winTitle !== "" && root.winTitle !== root.cap(root.appClass)
        text: "— " + root.winTitle
        font.family: Theme.fonts.sans
        font.pixelSize: 14
        color: Theme.textDim
        elide: Text.ElideRight
    }
}
