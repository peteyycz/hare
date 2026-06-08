import QtQuick
import QtQuick.Layouts

// Top block of the NetworkPanel — managed wired connection. Renders nothing
// when no managed ethernet device is present (driven by Networks singleton).
//
// One row: 36px circular icon ring on the left, two lines of text (device +
// state), and a single Connect / Disconnect action button. Active state paints
// with the accent to mirror NetworkItem so all three blocks read the same way.
ColumnLayout {
    id: section

    visible: Networks.ethernetDevice.length > 0
    spacing: Theme.gap

    Text {
        text: "Ethernet"
        font.family: Theme.fonts.sans
        font.pixelSize: 15
        font.weight: Font.DemiBold
        color: Theme.text
    }

    Rectangle {
        id: row

        readonly property bool connected: Networks.ethernetState === "connected"
        readonly property bool unavailable: Networks.ethernetState === "unavailable"

        Layout.fillWidth: true
        implicitHeight: 62
        radius: Theme.rMd
        color: connected ? Theme.accent : Theme.fill
        border.width: 1
        border.color: connected ? "transparent" : Theme.hairline

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

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: row.connected ? Theme.rgba("ffffff", 0.22) : Theme.fillStrong

                Icon {
                    anchors.centerIn: parent
                    code: 0xf6ff // nf-fa-network_wired
                    size: 17
                    color: row.connected ? Theme.accentInk : Theme.text
                    opacity: row.unavailable ? 0.5 : 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.connected && Networks.ethernetConnection.length > 0 ? Networks.ethernetConnection : Networks.ethernetDevice
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: row.connected ? Theme.accentInk : Theme.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (Networks.ethernetBusy)
                            return "Working…";
                        if (row.connected)
                            return "Connected";
                        if (row.unavailable)
                            return "Cable unplugged";
                        return "Disconnected";
                    }
                    font.family: Theme.fonts.sans
                    font.pixelSize: 11
                    color: row.connected ? Theme.accentInk : Theme.textDim
                    opacity: row.connected ? 0.8 : 1
                    elide: Text.ElideRight
                }
            }

            // Action button — Disconnect on the active row (over accent fill),
            // Connect otherwise. Hidden when the link is unavailable (no
            // carrier) since there is nothing meaningful to do.
            Rectangle {
                id: actionBtn
                Layout.alignment: Qt.AlignVCenter
                visible: !row.unavailable
                implicitHeight: 32
                implicitWidth: actionText.implicitWidth + 26
                radius: Theme.rSm
                color: {
                    if (row.connected)
                        return actionMouse.containsMouse ? Theme.rgba("ffffff", 0.32) : Theme.rgba("ffffff", 0.18);
                    return actionMouse.containsMouse ? Theme.accent : Theme.fillStrong;
                }
                border.width: 1
                border.color: row.connected ? "transparent" : (actionMouse.containsMouse ? "transparent" : Theme.hairline)

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: Networks.ethernetBusy ? "…" : (row.connected ? "Disconnect" : "Connect")
                    font.family: Theme.fonts.sans
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: row.connected ? Theme.accentInk : (actionMouse.containsMouse ? Theme.accentInk : Theme.text)
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Networks.ethernetBusy
                    onClicked: Networks.toggleEthernet()
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Networks.ethernetError.length > 0
        wrapMode: Text.WordWrap
        text: Networks.ethernetError
        color: Theme.error
        font.family: Theme.fonts.sans
        font.pixelSize: 11
    }
}
