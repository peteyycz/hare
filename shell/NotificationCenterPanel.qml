import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Notification Center — the mockup's `#notif`: a floating header + a scrollable
// stack of glass NotifCards at the top-right (no container glass; the cards are
// the glass). A layer-shell surface toggled by the bell bar button, mirroring
// the ControlCenterPanel placement.
PanelWindow {
    id: panel

    property bool open: false
    readonly property var items: Notifs.list?.values ?? []
    // cap the scroll viewport so the window stays on-screen; the list scrolls
    readonly property int maxListHeight: (screen?.height ?? 1080) - Theme.barHeight - 80

    visible: open
    color: "transparent"

    WlrLayershell.namespace: "hare"
    WlrLayershell.layer: WlrLayer.Top

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
    implicitHeight: col.implicitHeight

    onVisibleChanged: Notifs.panelOpen = visible

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        // tight gap between the header and the card stack; cards keep Theme.gap
        // between themselves (see listCol below)
        spacing: 6

        // ---- header ----
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            implicitHeight: 20

            // soft shadow for legibility over the wallpaper
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 1
                y: 1
                text: "Notifications"
                font.family: Theme.fonts.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Qt.rgba(0, 0, 0, 0.35)
                visible: Theme.activeTone === "dark"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                font.family: Theme.fonts.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.text
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible: panel.items.length > 0
                text: "Clear All"
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                color: clearMouse.containsMouse ? Theme.text : Theme.textDim

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
        }

        // ---- empty state ----
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            visible: panel.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No notifications"
            font.family: Theme.fonts.sans
            font.pixelSize: 13
            color: Theme.textDim
        }

        // ---- list (newest first, scrolls past the cap) ----
        // Safe to use a Flickable now that NotifCard is a plain Rectangle (no
        // ShaderEffectSource — see NotifCard.qml).
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(listCol.implicitHeight, panel.maxListHeight)
            visible: panel.items.length > 0
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
                    model: panel.items.slice().reverse()

                    // each card fades + slides in, staggered top-to-bottom, when
                    // the center opens (reverts when it closes, so it replays)
                    delegate: NotifCard {
                        id: card
                        required property var modelData
                        required property int index
                        notification: modelData
                        mode: "center"

                        opacity: 0
                        transform: Translate {
                            id: slide
                            y: 8
                        }
                        states: State {
                            name: "in"
                            when: panel.visible
                            PropertyChanges {
                                target: card
                                opacity: 1
                            }
                            PropertyChanges {
                                target: slide
                                y: 0
                            }
                        }
                        transitions: Transition {
                            to: "in"
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: card.index * 45
                                }
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: card
                                        property: "opacity"
                                        to: 1
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: slide
                                        property: "y"
                                        to: 0
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
