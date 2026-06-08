import QtQuick
import "../../Theme"
import "../../Common"
import "../../Services"
import "../../Bar"

// Bar bell button → toggles the Notification Center. Shows an accent unread
// badge with the tracked-notification count.
BarButton {
    id: root

    property bool open: false
    active: open

    readonly property int count: NotificationService.list?.values?.length ?? 0
    // auto-close once the last notification is gone (Clear All or per-card (x))
    onCountChanged: if (count === 0)
        root.open = false

    // don't open an empty center — only toggle when there's something to show
    // (still allow closing if it's already open)
    onClicked: {
        if (!root.open && count === 0)
            return;
        root.open = !root.open;
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        code: 0xf0f3 // nf-fa-bell

        Rectangle {
            readonly property int count: root.count

            visible: count > 0 && !root.open
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.top
            anchors.horizontalCenterOffset: -1
            anchors.verticalCenterOffset: 2
            implicitWidth: Math.max(14, badge.implicitWidth + 6)
            implicitHeight: 14
            radius: 7
            color: Theme.accent
            border.width: 1
            border.color: Theme.bgSolid

            Text {
                id: badge
                anchors.centerIn: parent
                text: parent.count > 9 ? "9+" : parent.count
                font.family: Theme.fonts.sans
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Theme.accentInk
            }
        }
    }
}
