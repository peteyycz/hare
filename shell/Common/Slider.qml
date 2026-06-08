import QtQuick
import QtQuick.Layouts
import "../Theme"

// Liquid-glass horizontal slider: a pill track with an accent fill and a
// leading glyph (matches the design's `.slider`). Drag to scrub. Reports the
// new fraction via `moved(v)` rather than mutating `value`, so callers can keep
// `value` bound to a live source (Pipewire, brightnessctl, …) without breaking
// the binding. While dragging it shows an optimistic local position so the
// fill tracks the cursor instantly.
Item {
    id: root

    property real value: 0      // 0..1, normally bound to a live source
    property int glyph: 0       // leading Nerd Font codepoint
    signal moved(real v)

    Layout.fillWidth: true
    implicitHeight: 30

    property bool _dragging: false
    property real _drag: 0
    readonly property real shown: Math.max(0, Math.min(1, _dragging ? _drag : value))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.fill
        border.width: 1
        border.color: Theme.hairline
        clip: true

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            // never let the fill collapse below the rounded cap
            width: Math.max(height, parent.width * root.shown)
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(Theme.accent, 1.06)
                }
                GradientStop {
                    position: 1.0
                    color: Theme.accent
                }
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 9
            code: root.glyph
            size: 14
            color: Theme.accentInk
            opacity: 0.9
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function scrub(x) {
            root._drag = Math.max(0, Math.min(1, x / width));
            root._dragging = true;
            root.moved(root._drag);
        }

        onPressed: e => scrub(e.x)
        onPositionChanged: e => {
            if (pressed)
                scrub(e.x);
        }
        onReleased: root._dragging = false
        onCanceled: root._dragging = false
    }
}
