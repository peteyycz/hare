import QtQuick
import QtQuick.Layouts

// Bottom block of the NetworkPanel — saved VPN / WireGuard profiles. Hidden
// when no VPN profile exists. Each row is a single-tap toggle (VpnItem).
ColumnLayout {
    id: section

    visible: Networks.vpns.length > 0
    spacing: Theme.gap

    Text {
        text: "VPN"
        font.family: Theme.fonts.sans
        font.pixelSize: 15
        font.weight: Font.DemiBold
        color: Theme.text
    }

    Repeater {
        model: Networks.vpns

        delegate: VpnItem {
            required property var modelData
            vpn: modelData
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Networks.vpnError.length > 0
        wrapMode: Text.WordWrap
        text: Networks.vpnError
        color: Theme.error
        font.family: Theme.fonts.sans
        font.pixelSize: 11
    }
}
