import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme"
import "../../Common"
import "../../Services"

// Network panel — a layer-shell popup mirroring ControlCenterPanel. Three
// stacked blocks, all driven by NetworkService:
//   1. Ethernet — only visible when a managed wired link exists.
//   2. Wi-Fi    — visible networks, radio toggle, rescan, inline password.
//   3. VPN      — saved VPN/WireGuard profiles; hidden when none configured.
// Thin hairline dividers separate adjacent blocks so they read as discrete
// sections without each needing its own background card.
//
// `keyboardFocus: OnDemand` is required so the password TextInput can take
// focus — without it the layer surface gets no keyboard at all and typing
// would be a no-op.
PanelWindow {
    id: panel

    property bool open: false

    // Only one row may be expanded at a time; toggling another collapses the
    // previous. Reset every time the panel opens so we don't reopen on a
    // password input for a stale row.
    property string expandedSsid: ""

    visible: open
    color: "transparent"

    WlrLayershell.namespace: "hare"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.popupGap
        right: Theme.popupEdge
    }
    exclusiveZone: 0

    implicitWidth: 372
    implicitHeight: col.implicitHeight + Theme.pad * 2

    onOpenChanged: {
        if (open) {
            panel.expandedSsid = "";
            NetworkService.refresh();
        }
    }

    GlassSurface {
        anchors.fill: parent
        shown: panel.visible

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap

            // ---- block 1: ethernet ----
            EthernetItem {
                Layout.fillWidth: true
            }

            // Hairline divider above wifi only when ethernet is present.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                visible: NetworkService.ethernetDevice.length > 0
                color: Theme.hairline
            }

            // ---- block 2: wi-fi ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Wi-Fi"
                        font.family: Theme.fonts.sans
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Wi-Fi radio toggle pill
                    Rectangle {
                        implicitWidth: radioText.implicitWidth + 22
                        implicitHeight: 28
                        radius: Theme.rPill
                        color: NetworkService.wifiEnabled ? Theme.fillStrong : Theme.fill
                        border.width: 1
                        border.color: Theme.hairline

                        Text {
                            id: radioText
                            anchors.centerIn: parent
                            text: NetworkService.wifiEnabled ? "On" : "Off"
                            font.family: Theme.fonts.sans
                            font.pixelSize: 11
                            color: Theme.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkService.toggleWifi()
                        }
                    }

                    // Refresh button — fires a full nmcli rescan + relist.
                    // While a scan is in flight the chip stays in its
                    // hover-highlighted colour and the glyph spins so the
                    // state is obvious without needing a "scanning…" label
                    // next to the header.
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: (refreshMouse.containsMouse || NetworkService.scanning) ? Theme.fillStrong : Theme.fill
                        border.width: 1
                        border.color: Theme.hairline

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }

                        Icon {
                            id: refreshIcon
                            anchors.centerIn: parent
                            code: 0xf021 // nf-fa-refresh
                            size: 12
                            color: Theme.text

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: NetworkService.scanning
                                onRunningChanged: if (!running)
                                    refreshIcon.rotation = 0
                            }
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: NetworkService.wifiEnabled
                            onClicked: NetworkService.refresh()
                        }
                    }
                }

                // ---- wifi-disabled state ----
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    visible: !NetworkService.wifiEnabled
                    horizontalAlignment: Text.AlignHCenter
                    text: "Wi-Fi is off"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    color: Theme.textDim
                }

                // ---- empty state ----
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    visible: NetworkService.wifiEnabled && NetworkService.networks.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: NetworkService.scanning ? "Scanning…" : "No networks found"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    color: Theme.textDim
                }

                // ---- list ----
                // Cap the viewport so the panel stays on-screen if a lot of
                // APs are visible; the list scrolls past the cap.
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(listCol.implicitHeight, 320)
                    visible: NetworkService.wifiEnabled && NetworkService.networks.length > 0
                    contentWidth: width
                    contentHeight: listCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    ColumnLayout {
                        id: listCol
                        width: parent.width
                        spacing: Theme.gap

                        Repeater {
                            model: NetworkService.networks

                            delegate: WifiItem {
                                required property var modelData
                                net: modelData
                                expanded: panel.expandedSsid === modelData.ssid
                                onToggle: panel.expandedSsid = (panel.expandedSsid === modelData.ssid) ? "" : modelData.ssid
                            }
                        }
                    }
                }

                // ---- error banner ----
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: NetworkService.lastError.length > 0
                    wrapMode: Text.WordWrap
                    text: NetworkService.lastError
                    color: Theme.error
                    font.family: Theme.fonts.sans
                    font.pixelSize: 11
                }
            }

            // Hairline divider above VPN only when at least one profile exists.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                visible: NetworkService.vpns.length > 0
                color: Theme.hairline
            }

            // ---- block 3: VPN ----
            VpnSection {
                Layout.fillWidth: true
            }
        }
    }
}
