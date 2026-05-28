import QtQuick

// Control-center toggle. The panel itself isn't built yet, so this is the
// styled entry point (no-op on click for now).
BarButton {
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf1de // nf-fa-sliders
    }
}
