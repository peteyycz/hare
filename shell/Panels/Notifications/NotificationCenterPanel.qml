import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme"
import "../../Services"

// Notification Center — the mockup's `#notif`: a floating header + a scrollable
// stack of glass NotificationCards at the top-right (no container glass; the cards are
// the glass). A layer-shell surface toggled by the bell bar button, mirroring
// the ControlCenterPanel placement.
PanelWindow {
    id: panel

    property bool open: false
    // pulsed once each time the center opens; cards animate their entrance off
    // this, NOT off `visible`, so a dismiss-driven list rebuild doesn't replay
    // the whole stagger.
    signal animateIn

    // Live, reversed view of the server's tracked notifications. Newest
    // first. Reading via a binding (rather than a deferred local copy +
    // Connections) is fine now that the Repeater below uses an integer-
    // count model — the VDMListDelegateDataType incubation crash that
    // motivated the original deferral can't fire on a count-based model.
    readonly property var items: (NotificationService.list?.values ?? []).slice().reverse()

    // Items grouped by source app (preserves newest-first order). Each
    // group is rendered as a single stacked NotificationGroup; the group fans out
    // on hover so individual notifications can be inspected/dismissed.
    readonly property var groups: {
        const arr = [];
        const byKey = {};
        for (const n of items) {
            const key = (n?.appName ?? "") || "_unknown";
            if (byKey[key] === undefined) {
                byKey[key] = arr.length;
                arr.push([]);
            }
            arr[byKey[key]].push(n);
        }
        return arr;
    }

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
        NotificationService.panelOpen = visible;
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
        // Two floating glass pills (matching the NotificationCards below) so they read
        // clearly over the wallpaper: the title on the left, "Clear All" on the
        // right, with space-between.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // title pill — same glass material as the NotificationCards (borderless bg
            // + specular sheen + edge highlight).
            Rectangle {
                id: titlePill
                implicitHeight: 28
                implicitWidth: titleText.implicitWidth + 24

                radius: Theme.rPill
                color: Theme.bg
                // borderless glass, like the bar
                antialiasing: true

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
                // brightening the Toggle tiles use in the Control Center
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
                    onClicked: NotificationService.clearAll()
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
        // Safe to use a Flickable now that NotificationCard is a plain Rectangle (no
        // ShaderEffectSource — see NotificationCard.qml).
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
                    // Integer-count model intentionally — not `panel.groups`.
                    // With a JS-array model Qt routes through
                    // VDMListDelegateDataType::createMissingProperties during
                    // delegate incubation and crashes on every notification
                    // (Qt 6 bug; reproduces independent of `required` keywords
                    // and of any `Qt.callLater` deferral). An integer count
                    // model uses a completely different delegate-model code
                    // path and side-steps the bug. The delegate looks up its
                    // backing group via `panel.groups[index]`.
                    model: panel.groups.length

                    delegate: NotificationGroup {
                        id: group
                        required property int index
                        items: panel.groups[group.index]
                        staggerIndex: group.index

                        Connections {
                            target: panel
                            function onAnimateIn() {
                                group.animateIn();
                            }
                        }
                    }
                }
            }
        }
    }
}
