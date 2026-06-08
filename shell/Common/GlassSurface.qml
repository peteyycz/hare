import QtQuick
import Quickshell.Widgets
import "../Theme"

// The rounded glass background used by every top-right popup panel
// (ControlCenter, Network, Bluetooth, Battery). A ClippingRectangle so
// children clip to the rounded corners (a plain `clip: true` only clips to
// the rectangular bounds and left glitchy nubs at the corners). Pops in
// with a scale-from-top-right + fade when `shown` becomes true.
//
// Consumers anchor.fill this and place their ColumnLayout etc. as child
// content (default property).
ClippingRectangle {
    id: root

    property bool shown: false
    default property alias content: container.data

    radius: Theme.rLg
    color: Theme.bg

    opacity: 0
    transform: Scale {
        id: popScale
        origin.x: root.width
        origin.y: 0
        xScale: 0.97
        yScale: 0.97
    }
    states: State {
        name: "shown"
        when: root.shown
        PropertyChanges {
            target: root
            opacity: 1
        }
        PropertyChanges {
            target: popScale
            xScale: 1
            yScale: 1
        }
    }
    transitions: Transition {
        NumberAnimation {
            properties: "opacity,xScale,yScale"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: container
        anchors.fill: parent
    }
}
