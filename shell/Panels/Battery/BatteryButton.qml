import QtQuick
import Quickshell.Services.UPower
import "../../Theme"
import "../../Common"
import "../../Services"
import "../../Bar"

// Battery level + percentage. Only shown on devices with a laptop battery.
// Clicking opens the BatteryPanel power-profile chooser — but only when
// powerprofilesctl is installed; otherwise the click is a no-op so we don't
// pop up an empty surface.
BarButton {
    id: root
    hpad: 7

    property bool open: false
    active: open

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isLaptopBattery ?? false
    readonly property int pct: {
        const v = dev?.percentage ?? 0;
        return Math.round(v > 1 ? v : v * 100);
    }
    readonly property bool charging: (dev?.state ?? 0) === 1

    visible: present

    onClicked: {
        if (PowerProfileService.available)
            root.open = !root.open;
    }

    function glyph(p) {
        if (p >= 88)
            return 0xf240; // full
        if (p >= 63)
            return 0xf241;
        if (p >= 38)
            return 0xf242;
        if (p >= 13)
            return 0xf243;
        return 0xf244; // empty
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: root.charging ? 0xf0e7 : root.glyph(root.pct) // bolt when charging
        color: root.pct <= 12 && !root.charging ? Theme.error : Theme.text
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.pct + "%"
        font.family: Theme.fonts.sans
        font.pixelSize: 13
        color: Theme.text
    }
}
