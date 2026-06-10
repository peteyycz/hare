import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme"
import "../../Common"
import "../../Services"

// Power menu — Shutdown / Restart / Suspend / Lock / Logout. A separate
// layer-shell surface anchored under the bar (top-right slot shared with the
// other popups). Activating any tile dispatches the action via PowerService
// and closes the popup so the button drops its open state.
PanelWindow {
    id: panel

    property bool open: false
    signal close

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
    implicitHeight: col.implicitHeight + Theme.pad * 2

    GlassSurface {
        anchors.fill: parent
        shown: panel.visible

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Theme.gap
                columnSpacing: Theme.gap

                Toggle {
                    icon: 0xf011 // power-off
                    name: "Shutdown"
                    status: "Power off"
                    onToggled: {
                        PowerService.shutdown();
                        panel.close();
                    }
                }
                Toggle {
                    icon: 0xf021 // arrows-rotate
                    name: "Restart"
                    status: "Reboot now"
                    onToggled: {
                        PowerService.reboot();
                        panel.close();
                    }
                }
                Toggle {
                    icon: 0xf236 // bed
                    name: "Suspend"
                    status: "Sleep"
                    onToggled: {
                        PowerService.suspend();
                        panel.close();
                    }
                }
                Toggle {
                    icon: 0xf023 // lock
                    name: "Lock"
                    status: "Lock screen"
                    onToggled: {
                        PowerService.lock();
                        panel.close();
                    }
                }
                Toggle {
                    icon: 0xf08b // sign-out
                    name: "Logout"
                    status: "End session"
                    onToggled: {
                        PowerService.logout();
                        panel.close();
                    }
                }
            }
        }
    }
}
