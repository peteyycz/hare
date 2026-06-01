import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// One notification, rendered as a floating glass card (the mockup's
// `.notif-card`: each card is its own glass surface, not a panel row). Shared by
// the Notification Center (`mode: "center"`, shows action buttons) and the
// transient toasts (`mode: "toast"`, terser).
//
// Deliberately a plain Rectangle + clip (NOT ClippingRectangle): a
// ShaderEffectSource-backed card crashes when nested in a Flickable (the
// scrollable center). The sheen is given matching top-corner radii so it doesn't
// overrun the rounded corners despite the rectangular clip.
Rectangle {
    id: root

    required property var notification
    property string mode: "center"          // "center" | "toast"
    readonly property bool toast: mode === "toast"

    Layout.fillWidth: true
    implicitWidth: 372
    // track the whole row (icon vs. text, whichever is taller) + 13px padding
    implicitHeight: rowContent.implicitHeight + 26

    radius: Theme.rLg
    color: Theme.bg
    // borderless glass, like the bar
    antialiasing: true
    clip: true

    // top specular sheen + 1px edge highlight (matches the bar / control
    // center) — light theme only, kept restrained in dark like the design
    Rectangle {
        visible: Theme.activeTone === "light"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: parent.height * 0.5
        // round the top corners to the card so the sheen doesn't paint into the
        // rounded-off corners (clip is rectangular, not rounded)
        topLeftRadius: root.radius
        topRightRadius: root.radius
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
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        height: 1
        color: Theme.hi
        opacity: 0.5
    }

    // body click → default action
    MouseArea {
        anchors.fill: parent
        z: -1 // below the close/action hit areas
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.invokeDefault(root.notification)
    }

    RowLayout {
        id: rowContent
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 13
        anchors.bottomMargin: 13
        spacing: 12

        // ---- app icon ----
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 34
            implicitHeight: 34
            radius: 9
            clip: true
            color: Notifs.accent(root.notification)

            Icon {
                anchors.centerIn: parent
                visible: appIcon.status !== Image.Ready
                code: 0xf0f3 // bell
                size: 16
                color: Theme.accentInk
            }
            IconImage {
                id: appIcon
                anchors.fill: parent
                asynchronous: true
                source: {
                    const n = root.notification;
                    if (!n)
                        return "";
                    if (n.image)
                        return n.image;
                    return n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "";
                }
                visible: status === Image.Ready
            }
        }

        // ---- text ----
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.notification?.summary || root.notification?.appName || "Notification"
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: Notifs.age(root.notification)
                    font.family: Theme.fonts.sans
                    font.pixelSize: 11
                    color: Theme.textFaint
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: closeMouse.containsMouse ? Theme.fill : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        code: 0xf00d // times
                        size: 11
                        color: Theme.textDim
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toast ? Notifs.dropToast(root.notification) : Notifs.dismiss(root.notification)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.notification?.body ?? ""
                textFormat: Text.StyledText
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                color: Theme.textDim
                wrapMode: Text.WordWrap
                maximumLineCount: root.toast ? 2 : 5
                elide: Text.ElideRight
            }

            // ---- actions (center only) ----
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6
                visible: !root.toast && (root.notification?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.notification?.actions ?? []

                    delegate: Rectangle {
                        required property var modelData
                        implicitHeight: 26
                        implicitWidth: actText.implicitWidth + 22
                        radius: Theme.rSm
                        color: actMouse.containsMouse ? Theme.fillStrong : Theme.fill
                        border.width: 1
                        border.color: Theme.hairline

                        Text {
                            id: actText
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.family: Theme.fonts.sans
                            font.pixelSize: 12
                            color: Theme.text
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                parent.modelData.invoke();
                                Notifs.dismiss(root.notification);
                            }
                        }
                    }
                }
            }
        }
    }
}
