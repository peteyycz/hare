import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Transient toast stack at the top-right of the primary screen. A layer-shell
// surface that hugs its content (so empty space below the cards stays
// click-through) and steps aside while a center/control panel is open. Each
// toast auto-dismisses (honouring the app's timeout; critical stays sticky).
PanelWindow {
    id: root

    visible: (Notifs.toasts.length > 0) && !Notifs.panelOpen
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
            model: Notifs.toasts

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

                Timer {
                    interval: {
                        const n = wrap.modelData;
                        if (n?.urgency === NotificationUrgency.Critical)
                            return 0; // sticky
                        const e = n?.expireTimeout ?? 0;
                        return e > 0 ? e : 5000;
                    }
                    running: interval > 0
                    repeat: false
                    onTriggered: Notifs.dropToast(wrap.modelData)
                }
            }
        }
    }
}
