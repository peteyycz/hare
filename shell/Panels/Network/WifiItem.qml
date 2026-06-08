import QtQuick
import QtQuick.Layouts
import "../../Theme"
import "../../Common"
import "../../Services"

// One row in the NetworkPanel list. Built to match the Control Center's
// Toggle: 62px tall pill with a 36px circular icon ring on the left, two
// lines of text (SSID + status), and an optional lock icon on the right when
// the network would prompt for a password. The active network paints with
// the accent (mirrors the Toggle "on" look).
//
// Clicking the header expands the row to reveal a password input (when
// needed) plus a Connect / Disconnect action. Hover/click hit area lives on
// the header sub-area so clicking the password input or button doesn't
// double as a header tap that would collapse the row mid-input.
Rectangle {
    id: item

    required property var net  // { ssid, signal, security, active, known }
    property bool expanded: false
    signal toggle

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    radius: Theme.rMd
    color: net.active ? Theme.accent : (item.expanded || hover.containsMouse ? Theme.fillStrong : Theme.fill)
    border.width: 1
    border.color: net.active ? "transparent" : Theme.hairline

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    // Focus the password input the moment the row expands so the user can
    // start typing without an extra click. Skip for active rows — they only
    // expose a Disconnect button, no input.
    onExpandedChanged: if (expanded && !net.active)
        Qt.callLater(() => pwInput.forceActiveFocus())

    function statusText() {
        if (net.active)
            return "Connected";
        if (NetworkService.connectingSsid === net.ssid)
            return "Connecting…";
        const sec = net.security.length > 0 ? net.security : "Open";
        return net.known ? "Saved · " + sec : sec;
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        // ---- header row (62px tall, click target — same shape as Toggle) ----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 62

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 11

                // circular icon ring — wifi glyph dimmed by signal strength
                IconRing {
                    code: 0xf1eb // nf-fa-wifi
                    selected: item.net.active
                    iconOpacity: item.net.active ? 1 : (0.5 + (Math.min(100, item.net.signal) / 100) * 0.5)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: item.net.ssid
                        font.family: Theme.fonts.sans
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: item.net.active ? Theme.accentInk : Theme.text
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: item.statusText()
                        font.family: Theme.fonts.sans
                        font.pixelSize: 11
                        color: item.net.active ? Theme.accentInk : Theme.textDim
                        opacity: item.net.active ? 0.8 : 1
                        elide: Text.ElideRight
                    }
                }

                // Lock only when the user would actually be prompted: secured
                // AND not a saved profile (nmcli reuses stored creds) AND not
                // already the active connection.
                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    visible: item.net.security.length > 0 && !item.net.known && !item.net.active
                    code: 0xf023 // nf-fa-lock
                    size: 13
                    color: Theme.textDim
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

        // ---- expanded: password (when needed) + action ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 14
            visible: item.expanded
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.rSm
                color: item.net.active ? Theme.rgba("ffffff", 0.18) : Theme.bg
                border.width: 1
                border.color: pwInput.activeFocus ? Theme.accent : (item.net.active ? "transparent" : Theme.hairline)
                // Hidden for open networks, saved profiles, and the active
                // connection — none of those need a password entered here.
                visible: !item.net.active && item.net.security.length > 0 && !item.net.known

                TextInput {
                    id: pwInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    echoMode: TextInput.Password
                    selectByMouse: true
                    clip: true
                    onAccepted: actionBtn.go()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: pwInput.text.length === 0 && !pwInput.activeFocus
                        text: "Password"
                        color: Theme.textFaint
                        font: pwInput.font
                    }
                }
            }

            // When the password field is hidden the action button needs a
            // spacer to keep it right-aligned instead of stretching.
            Item {
                Layout.fillWidth: true
                visible: item.net.active || item.net.security.length === 0 || item.net.known
            }

            // Action button — Disconnect on the active row (styled against the
            // accent fill), Connect everywhere else.
            ActionButton {
                text: item.net.active ? "Disconnect" : "Connect"
                selected: item.net.active
                busy: NetworkService.connectingSsid === item.net.ssid
                onClicked: {
                    if (item.net.active)
                        NetworkService.disconnect(item.net.ssid);
                    else
                        NetworkService.connect(item.net.ssid, pwInput.text);
                    pwInput.text = "";
                    item.toggle();
                }
            }
        }
    }
}
