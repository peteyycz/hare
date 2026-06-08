import QtQuick
import QtQuick.Layouts
import "../Theme"

// One Control Center quick-toggle tile (the design's `.cc-toggle`): a circular
// icon ring + name/status label that fills with the accent when `on`. Purely
// presentational — the owner binds `on`/`status` to a backend and handles
// `toggled()`.
Rectangle {
    id: root

    property int icon: 0
    property string name: ""
    property string status: ""
    property bool on: false
    signal toggled

    Layout.fillWidth: true
    Layout.preferredHeight: 62
    radius: Theme.rMd
    color: on ? Theme.accent : (mouse.containsMouse ? Theme.fillStrong : Theme.fill)
    border.width: 1
    border.color: on ? "transparent" : Theme.hairline

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 11

        IconRing {
            code: root.icon
            selected: root.on
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.name
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.on ? Theme.accentInk : Theme.text
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.status
                font.family: Theme.fonts.sans
                font.pixelSize: 11
                color: root.on ? Theme.accentInk : Theme.textDim
                opacity: root.on ? 0.8 : 1
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
