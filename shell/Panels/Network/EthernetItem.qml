import QtQuick
import QtQuick.Layouts
import "../../Theme"
import "../../Common"
import "../../Services"

// Top block of the NetworkPanel — managed wired connection. Renders nothing
// when no managed ethernet device is present (driven by NetworkService).
//
// One row: 36px circular icon ring on the left, two lines of text (device +
// state), and a single Connect / Disconnect action button. Active state paints
// with the accent to mirror WifiItem so all three blocks read the same way.
ColumnLayout {
    id: section

    visible: NetworkService.ethernetDevice.length > 0
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

        readonly property bool connected: NetworkService.ethernetState === "connected"
        readonly property bool unavailable: NetworkService.ethernetState === "unavailable"

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

            IconRing {
                code: 0xf6ff // nf-fa-network_wired
                selected: row.connected
                iconOpacity: row.unavailable ? 0.5 : 1
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.connected && NetworkService.ethernetConnection.length > 0 ? NetworkService.ethernetConnection : NetworkService.ethernetDevice
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: row.connected ? Theme.accentInk : Theme.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (NetworkService.ethernetBusy)
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
            ActionButton {
                Layout.alignment: Qt.AlignVCenter
                visible: !row.unavailable
                text: row.connected ? "Disconnect" : "Connect"
                selected: row.connected
                busy: NetworkService.ethernetBusy
                enabled: !NetworkService.ethernetBusy
                onClicked: NetworkService.toggleEthernet()
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: NetworkService.ethernetError.length > 0
        wrapMode: Text.WordWrap
        text: NetworkService.ethernetError
        color: Theme.error
        font.family: Theme.fonts.sans
        font.pixelSize: 11
    }
}
