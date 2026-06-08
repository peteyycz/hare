import QtQuick
import QtQuick.Layouts
import "../../Theme"
import "../../Common"
import "../../Services"

// One row in the VPN list. Same 62px pill shape as WifiItem, but without
// password input or signal strength — a VPN profile is either active or not,
// so the row is a single tap to toggle.
Rectangle {
    id: item

    required property var vpn  // { name, type, active }

    Layout.fillWidth: true
    implicitHeight: 62
    radius: Theme.rMd
    color: vpn.active ? Theme.accent : (hover.containsMouse ? Theme.fillStrong : Theme.fill)
    border.width: 1
    border.color: vpn.active ? "transparent" : Theme.hairline

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
            color: item.vpn.active ? Theme.rgba("ffffff", 0.22) : Theme.fillStrong

            Icon {
                anchors.centerIn: parent
                code: 0xf084 // nf-fa-key
                size: 16
                color: item.vpn.active ? Theme.accentInk : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: item.vpn.name
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: item.vpn.active ? Theme.accentInk : Theme.text
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: {
                    if (NetworkService.connectingVpn === item.vpn.name)
                        return item.vpn.active ? "Disconnecting…" : "Connecting…";
                    if (item.vpn.active)
                        return "Connected";
                    return item.vpn.type === "wireguard" ? "WireGuard" : "VPN";
                }
                font.family: Theme.fonts.sans
                font.pixelSize: 11
                color: item.vpn.active ? Theme.accentInk : Theme.textDim
                opacity: item.vpn.active ? 0.8 : 1
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: NetworkService.connectingVpn === ""
        onClicked: {
            if (item.vpn.active)
                NetworkService.disconnectVpn(item.vpn.name);
            else
                NetworkService.connectVpn(item.vpn.name);
        }
    }
}
