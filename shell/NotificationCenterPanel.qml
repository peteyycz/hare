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
    // pulsed once each time the center opens; cards animate their entrance off
    // this, NOT off `visible`, so a dismiss-driven list rebuild doesn't replay
    // the whole stagger.
    signal animateIn

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

    onVisibleChanged: {
        Notifs.panelOpen = visible;
        // fire after the delegates exist for this show, but before the next frame
        if (visible)
            Qt.callLater(() => panel.animateIn());
    }

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
        // Two floating glass pills (matching the NotifCards below) so they read
        // clearly over the wallpaper: the title on the left, "Clear All" on the
        // right, with space-between.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // title pill — same glass material as the NotifCards (borderless bg
            // + specular sheen + edge highlight).
            Rectangle {
                id: titlePill
                implicitHeight: 28
                implicitWidth: titleText.implicitWidth + 24

                radius: Theme.rPill
                color: Theme.bg
                // borderless glass, like the bar
                antialiasing: true

                // top specular sheen — a full-size overlay sharing the pill's
                // radius, so it follows the rounded corners without a clip; the
                // gradient fades out by the middle (light theme only)
                Rectangle {
                    visible: Theme.activeTone === "light"
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(1, 1, 1, 0.10)
                        }
                        GradientStop {
                            position: 0.5
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1.0
                            color: "transparent"
                        }
                    }
                }
                // 1px top edge highlight — light theme only
                Rectangle {
                    visible: Theme.activeTone === "light"
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    anchors.topMargin: 1
                    anchors.leftMargin: parent.height / 2
                    anchors.rightMargin: parent.height / 2
                    height: 1
                    color: Theme.hi
                    opacity: 0.5
                }

                Text {
                    id: titleText
                    anchors.centerIn: parent
                    text: "Notifications"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.text
                }
            }

            // spacer → pushes the two pills to opposite edges (space-between)
            Item {
                Layout.fillWidth: true
            }

            // clear-all pill — same glass material as the title pill, with the
            // animated fill→fillStrong hover used by the preferences buttons.
            Rectangle {
                id: clearPill
                visible: panel.items.length > 0
                implicitHeight: 28
                implicitWidth: clearText.implicitWidth + 24

                radius: Theme.rPill
                color: Theme.bg
                // borderless glass, like the bar
                antialiasing: true

                // hover wash — a fillStrong highlight fades in on hover, the same
                // brightening the CcToggle buttons use in the Control Center
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: clearMouse.containsMouse ? Theme.fillStrong : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }
                }

                // top specular sheen — a full-size overlay sharing the pill's
                // radius, so it follows the rounded corners without a clip; the
                // gradient fades out by the middle (light theme only)
                Rectangle {
                    visible: Theme.activeTone === "light"
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(1, 1, 1, 0.10)
                        }
                        GradientStop {
                            position: 0.5
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1.0
                            color: "transparent"
                        }
                    }
                }
                // 1px top edge highlight — light theme only
                Rectangle {
                    visible: Theme.activeTone === "light"
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    anchors.topMargin: 1
                    anchors.leftMargin: parent.height / 2
                    anchors.rightMargin: parent.height / 2
                    height: 1
                    color: Theme.hi
                    opacity: 0.5
                }

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 12
                    color: clearMouse.containsMouse ? Theme.text : Theme.textDim
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
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

                        // Cards default to fully shown, so a rebuild (e.g. after a
                        // dismiss) just reappears them in place. The staggered
                        // fade+slide only runs when the panel pulses `animateIn`.
                        transform: Translate {
                            id: slide
                            y: 0
                        }
                        Connections {
                            target: panel
                            function onAnimateIn() {
                                card.opacity = 0;
                                slide.y = 8;
                                enterAnim.restart();
                            }
                        }
                        SequentialAnimation {
                            id: enterAnim
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
