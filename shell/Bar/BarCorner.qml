import QtQuick
import "../Theme"

// A single concave ("negative rounding") corner fillet for the notched bar: a
// `size`×`size` glass wedge that hangs below a bar edge with a quarter-circle
// scooped out toward the screen, so the bar appears to curve down into the
// desktop. Port of the design's `.bar-corner` (a radial-gradient mask).
//
// `side` is "left" or "right". The fill matches the bar glass and — since this
// lives on the same layer-shell surface ("hare") — the compositor blur shows
// through it; the carved-out area is transparent (unblurred wallpaper).
Item {
    id: root

    property string side: "left"
    property int size: 18
    property color color: Theme.bg

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const s = root.size;
            ctx.reset();
            ctx.fillStyle = root.color;
            ctx.beginPath();
            if (root.side === "left") {
                // fill the top-left wedge; carve a circle centred at the
                // bottom-right corner (scoops away from the screen edge)
                ctx.moveTo(0, 0);
                ctx.lineTo(s, 0);
                ctx.arc(s, s, s, -Math.PI / 2, Math.PI, true);
            } else {
                // mirror: fill the top-right wedge; carve from the bottom-left
                ctx.moveTo(0, 0);
                ctx.lineTo(s, 0);
                ctx.lineTo(s, s);
                ctx.arc(0, s, s, 0, -Math.PI / 2, true);
            }
            ctx.closePath();
            ctx.fill();
        }

        // repaint when the look changes (theme toggle, size, side)
        Connections {
            target: root
            function onColorChanged() {
                canvas.requestPaint();
            }
            function onSideChanged() {
                canvas.requestPaint();
            }
            function onSizeChanged() {
                canvas.requestPaint();
            }
        }
    }
}
