import QtQuick
import QtQuick.Layouts
import "../../Theme"
import "../../Common"
import "../../Services"

// One row in the BluetoothPanel list — sister to WifiItem and styled the
// same way as a Toggle: 62px tall pill with a circular icon ring + two
// lines of text (name + status). The connected device paints with the
// accent. Clicking expands the row to reveal a primary action button
// (Connect / Disconnect / Pair) — bluetooth has no inline password concept,
// so there's no text input in the expanded view.
Rectangle {
    id: item

    required property var dev  // BluetoothDevice
    property bool expanded: false
    signal toggle

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    radius: Theme.rMd
    color: dev?.connected ? Theme.accent : (item.expanded || hover.containsMouse ? Theme.fillStrong : Theme.fill)
    border.width: 1
    border.color: dev?.connected ? "transparent" : Theme.hairline

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    readonly property bool busy: BluetoothService.busyAddress !== "" && BluetoothService.busyAddress === (dev?.address ?? "")

    function statusText() {
        if (item.busy)
            return dev?.connected ? "Disconnecting…" : (dev?.paired ? "Connecting…" : "Pairing…");
        if (dev?.connected) {
            const pct = item.batteryPercent();
            return pct !== null ? "Connected · " + pct + "%" : "Connected";
        }
        if (dev?.paired)
            return "Paired";
        return "Available";
    }

    function batteryPercent() {
        const b = dev?.battery;
        if (b === undefined || b === null)
            return null;
        // BlueZ exposes battery as 0..1 in some bindings, 0..100 in others —
        // normalise either way before rendering.
        return b <= 1 ? Math.round(b * 100) : Math.round(b);
    }

    // BlueZ device-class icon name → Nerd Font glyph. Falls back to the
    // bluetooth glyph for anything we don't recognise.
    function deviceIcon() {
        const ico = (dev?.icon ?? "") + "";
        if (ico.indexOf("audio") !== -1 || ico.indexOf("headphones") !== -1 || ico.indexOf("headset") !== -1 || ico.indexOf("speaker") !== -1)
            return 0xf025; // headphones
        if (ico.indexOf("keyboard") !== -1)
            return 0xf11c; // keyboard
        if (ico.indexOf("mouse") !== -1)
            return 0xf245; // mouse-pointer
        if (ico.indexOf("phone") !== -1)
            return 0xf10b; // mobile-phone
        if (ico.indexOf("computer") !== -1 || ico.indexOf("laptop") !== -1)
            return 0xf108; // desktop
        if (ico.indexOf("camera") !== -1)
            return 0xf030; // camera
        if (ico.indexOf("gaming") !== -1 || ico.indexOf("gamepad") !== -1 || ico.indexOf("joystick") !== -1)
            return 0xf11b; // gamepad
        if (ico.indexOf("watch") !== -1)
            return 0xf017; // clock
        return 0xf293; // bluetooth
    }

    function actionLabel() {
        if (item.busy)
            return "…";
        if (dev?.connected)
            return "Disconnect";
        if (dev?.paired)
            return "Connect";
        return "Pair";
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        // ---- header (62px, click target — Toggle proportions) ----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 62

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 11

                IconRing {
                    code: item.deviceIcon()
                    selected: item.dev?.connected ?? false
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: item.dev?.name ?? item.dev?.address ?? "Unknown"
                        font.family: Theme.fonts.sans
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: item.dev?.connected ? Theme.accentInk : Theme.text
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: item.statusText()
                        font.family: Theme.fonts.sans
                        font.pixelSize: 11
                        color: item.dev?.connected ? Theme.accentInk : Theme.textDim
                        opacity: item.dev?.connected ? 0.8 : 1
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: item.toggle()
            }
        }

        // ---- expanded: single action button ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 14
            visible: item.expanded
            spacing: 8

            // Spacer pushes the action button to the right — bluetooth rows
            // never carry a left-side input, so the spacer is always there.
            Item {
                Layout.fillWidth: true
            }

            ActionButton {
                text: item.actionLabel()
                selected: item.dev?.connected ?? false
                onClicked: {
                    if (!item.dev)
                        return;
                    if (item.dev.connected)
                        BluetoothService.disconnect(item.dev);
                    else
                        BluetoothService.connect(item.dev);
                    item.toggle();
                }
            }
        }
    }
}
