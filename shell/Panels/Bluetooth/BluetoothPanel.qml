import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme"
import "../../Common"
import "../../Services"

// Bluetooth panel — sibling of NetworkPanel. Same liquid-glass surface,
// header with on/off + refresh, scrollable list of BluetoothItem rows.
// Discovery is started on every open (and again on the refresh button),
// auto-stopping after BluetoothService.scanStop fires.
//
// `keyboardFocus: OnDemand` is kept symmetric with the other top-right
// popups (and harmless here — bluetooth rows don't accept text input).
PanelWindow {
    id: panel

    property bool open: false

    // Only one row may be expanded at a time so the panel doesn't grow
    // unbounded. Address is used as the row identity (names can collide).
    property string expandedAddress: ""

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
            panel.expandedAddress = "";
            if (BluetoothService.enabled)
                BluetoothService.refresh();
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

            // ---- header ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Bluetooth"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Item {
                    Layout.fillWidth: true
                }

                // adapter on/off pill
                Rectangle {
                    implicitWidth: radioText.implicitWidth + 22
                    implicitHeight: 28
                    radius: Theme.rPill
                    color: BluetoothService.enabled ? Theme.fillStrong : Theme.fill
                    border.width: 1
                    border.color: Theme.hairline

                    Text {
                        id: radioText
                        anchors.centerIn: parent
                        text: BluetoothService.enabled ? "On" : "Off"
                        font.family: Theme.fonts.sans
                        font.pixelSize: 11
                        color: Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: BluetoothService.adapter !== null
                        onClicked: BluetoothService.toggleAdapter()
                    }
                }

                // refresh / start-discovery button. While discovery is
                // running the chip stays highlighted and the glyph spins —
                // same convention as the Wi-Fi panel, so no "scanning…" label
                // is needed in the header.
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: (refreshMouse.containsMouse || BluetoothService.discovering) ? Theme.fillStrong : Theme.fill
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
                            running: BluetoothService.discovering
                            onRunningChanged: if (!running)
                                refreshIcon.rotation = 0
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: BluetoothService.enabled
                        onClicked: BluetoothService.refresh()
                    }
                }
            }

            // ---- empty / off states ----
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: BluetoothService.adapter === null
                horizontalAlignment: Text.AlignHCenter
                text: "No Bluetooth adapter"
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                color: Theme.textDim
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: BluetoothService.adapter !== null && !BluetoothService.enabled
                horizontalAlignment: Text.AlignHCenter
                text: "Bluetooth is off"
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                color: Theme.textDim
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: BluetoothService.enabled && BluetoothService.sortedDevices.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: BluetoothService.discovering ? "Scanning…" : "No devices"
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                color: Theme.textDim
            }

            // ---- list ----
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(listCol.implicitHeight, 420)
                visible: BluetoothService.enabled && BluetoothService.sortedDevices.length > 0
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
                        model: BluetoothService.sortedDevices

                        delegate: BluetoothItem {
                            required property var modelData
                            dev: modelData
                            expanded: panel.expandedAddress === (modelData?.address ?? "")
                            onToggle: {
                                const addr = modelData?.address ?? "";
                                panel.expandedAddress = (panel.expandedAddress === addr) ? "" : addr;
                            }
                        }
                    }
                }
            }

            // ---- error banner ----
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: BluetoothService.lastError.length > 0
                wrapMode: Text.WordWrap
                text: BluetoothService.lastError
                color: Theme.error
                font.family: Theme.fonts.sans
                font.pixelSize: 11
            }
        }
    }
}
