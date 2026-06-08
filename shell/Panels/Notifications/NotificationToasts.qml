import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme"
import "../../Services"

// Transient toast stack at the top-right of the primary screen. A layer-shell
// surface that hugs its content (so empty space below the cards stays
// click-through) and steps aside while a center/control panel is open. Each
// toast auto-dismisses (honouring the app's timeout; critical stays sticky).
PanelWindow {
    id: root

    // Read the toast queue straight from the singleton — the local-copy +
    // Connections + Qt.callLater dance is unnecessary now that the Repeater
    // below uses an integer-count model (the VDM incubation crash that
    // originally motivated it can't fire on a count-based model).
    readonly property var toasts: NotificationService.toasts

    visible: (toasts.length > 0) && !NotificationService.panelOpen
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
    implicitHeight: Math.max(1, col.implicitHeight)

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Theme.gap

        Repeater {
            // Integer-count model, not `root.toasts` — see NotificationCenter
            // Panel for the long explanation. Short version: a JS-array model
            // on a Repeater routes through VDMListDelegateDataType which
            // crashes the shell during delegate incubation on every
            // notification. An integer count uses a different delegate-model
            // path and bypasses the bug. The delegate reads its toast via
            // `root.toasts[index]`.
            model: root.toasts.length

            delegate: Item {
                id: wrap
                // With the integer-count model the delegate ONLY gets an
                // `index` context property — no `modelData`. We still need
                // to declare it `required` here: implicit context-property
                // lookup is unreliable from nested children (NotificationCard),
                // and without this declaration the binding below evaluates
                // `root.toasts[undefined]` → notification is null, and the
                // card falls back to its placeholder content.
                required property int index

                Layout.fillWidth: true
                implicitHeight: card.implicitHeight

                // slide-in + fade entrance (transform so the layout isn't fought)
                opacity: 0
                transform: Translate {
                    id: slide
                    x: 16
                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Component.onCompleted: {
                    opacity = 1;
                    slide.x = 0;
                }

                NotificationCard {
                    id: card
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    notification: root.toasts[wrap.index]
                    mode: "toast"
                }
                // auto-dismiss is scheduled per-toast in NotificationService, so
                // each toast disappears on its own clock (see NotificationService.pushToast)
            }
        }
    }
}
