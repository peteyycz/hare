import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Bluetooth panel — sibling of NetworkPanel. Same liquid-glass surface,
// header with on/off + refresh, scrollable list of BluetoothItem rows.
// Discovery is started on every open (and again on the refresh button),
// auto-stopping after Bluetooths.scanStop fires.
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
            if (Bluetooths.enabled)
                Bluetooths.refresh();
        }
    }

    ClippingRectangle {
        id: glass
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.bg

        opacity: 0
        transform: Scale {
            id: popScale
            origin.x: glass.width
            origin.y: 0
            xScale: 0.97
            yScale: 0.97
        }
        states: State {
            name: "shown"
            when: panel.visible
            PropertyChanges {
                target: glass
                opacity: 1
            }
            PropertyChanges {
                target: popScale
                xScale: 1
                yScale: 1
            }
        }
        transitions: Transition {
            NumberAnimation {
                properties: "opacity,xScale,yScale"
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        // top specular sheen — light theme only
        Rectangle {
            visible: Theme.activeTone === "light"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: parent.height * 0.4
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.10)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }
        Rectangle {
            visible: Theme.activeTone === "light"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.topMargin: 1
            anchors.leftMargin: glass.radius
            anchors.rightMargin: glass.radius
            height: 1
            color: Theme.hi
            opacity: 0.5
        }

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

                Text {
                    visible: Bluetooths.discovering
                    text: "scanning…"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 11
                    color: Theme.textDim
                }

                Item {
                    Layout.fillWidth: true
                }

                // adapter on/off pill
                Rectangle {
                    implicitWidth: radioText.implicitWidth + 22
                    implicitHeight: 28
                    radius: Theme.rPill
                    color: Bluetooths.enabled ? Theme.fillStrong : Theme.fill
                    border.width: 1
                    border.color: Theme.hairline

                    Text {
                        id: radioText
                        anchors.centerIn: parent
                        text: Bluetooths.enabled ? "On" : "Off"
                        font.family: Theme.fonts.sans
                        font.pixelSize: 11
                        color: Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: Bluetooths.adapter !== null
                        onClicked: Bluetooths.toggleAdapter()
                    }
                }

                // refresh / start-discovery button
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: refreshMouse.containsMouse ? Theme.fillStrong : Theme.fill
                    border.width: 1
                    border.color: Theme.hairline

                    Icon {
                        anchors.centerIn: parent
                        code: 0xf021 // nf-fa-refresh
                        size: 12
                        color: Theme.text
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: Bluetooths.enabled
                        onClicked: Bluetooths.refresh()
                    }
                }
            }

            // ---- empty / off states ----
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: Bluetooths.adapter === null
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
                visible: Bluetooths.adapter !== null && !Bluetooths.enabled
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
                visible: Bluetooths.enabled && Bluetooths.sortedDevices.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: Bluetooths.discovering ? "Scanning…" : "No devices"
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                color: Theme.textDim
            }

            // ---- list ----
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(listCol.implicitHeight, 420)
                visible: Bluetooths.enabled && Bluetooths.sortedDevices.length > 0
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
                        model: Bluetooths.sortedDevices

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
                visible: Bluetooths.lastError.length > 0
                wrapMode: Text.WordWrap
                text: Bluetooths.lastError
                color: Theme.error
                font.family: Theme.fonts.sans
                font.pixelSize: 11
            }
        }
    }
}
