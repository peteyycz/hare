import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Transient toast stack at the top-right of the primary screen. A layer-shell
// surface that hugs its content (so empty space below the cards stays
// click-through) and steps aside while a center/control panel is open. Each
// toast auto-dismisses (honouring the app's timeout; critical stays sticky).
PanelWindow {
    id: root

    // Local snapshot of the toast queue, refreshed via Qt.callLater whenever
    // Notifs.toasts changes. The Repeater reads this — not Notifs.toasts —
    // so the model reassignment lands in a fresh event-loop tick, away from
    // the synchronous binding chain that triggered it. Without this the
    // delegate incubation crashes inside VDMListDelegateDataType (same Qt
    // bug the Notifs.qml Qt.callLater partially worked around).
    property var toasts: []
    Connections {
        target: Notifs
        function onToastsChanged() {
            Qt.callLater(root._refreshToasts);
        }
    }
    function _refreshToasts() {
        root.toasts = Notifs.toasts.slice();
    }
    Component.onCompleted: root._refreshToasts()

    visible: (toasts.length > 0) && !Notifs.panelOpen
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
            model: root.toasts

            delegate: Item {
                id: wrap
                required property var modelData

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

                NotifCard {
                    id: card
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    notification: wrap.modelData
                    mode: "toast"
                }
                // auto-dismiss is scheduled per-toast in the Notifs singleton, so
                // each toast disappears on its own clock (see Notifs.pushToast)
            }
        }
    }
}
