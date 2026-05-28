import QtQuick

// Network indicator. quickshell 0.2.1 has no network service, so this is a
// static Wi-Fi glyph for now (cosmetic).
BarButton {
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf1eb // nf-fa-wifi
    }
}
