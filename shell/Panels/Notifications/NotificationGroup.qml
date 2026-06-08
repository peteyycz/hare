import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Theme"
import "../../Common"

// A group of notifications from the same app, rendered as a single stacked
// card in the notification center. Collapsed: top card + a couple of static
// "stub" peeks below it (each narrower than the one above, like a deck of
// cards) plus a count badge over the app icon. Hover: stubs fade out, the
// real trailing cards fade in as a vertical column.
//
// The animation is a pure opacity crossfade — NOT per-card y/scale/width
// animations. Earlier versions did all three and were sluggish:
//   - animating width forces NotificationCard's internal RowLayout/Text/Flow to
//     re-layout per frame
//   - animating the group's implicitHeight propagates up to
//     PanelWindow.implicitHeight, which re-configures the layer-shell
//     surface and re-blurs it every frame in the compositor
//
// Both of those are avoided here. implicitHeight snaps on expand (one
// configure + reblur) and snaps on collapse only after the fade completes
// (collapseTimer) — otherwise the panel would shrink underneath the
// still-visible cards and they'd pop out.
Item {
    id: root

    // Newest first. The card at index 0 is the front of the stack.
    required property var items
    // staggered fade-in index — set by the panel so groups cascade in.
    property int staggerIndex: 0

    signal animateIn

    Layout.fillWidth: true

    // ---- collapsed vs expanded ----
    // Only multi-item groups expand; a single-item group has nothing to fan
    // out, so hovering it shouldn't change anything.
    property bool expanded: hover.hovered && items.length > 1
    HoverHandler {
        id: hover
    }

    readonly property int peekHeight: 10          // visible bottom edge of each stub strip
    readonly property int peekInset: 10           // horizontal inset per stub level (deck-of-cards look)
    readonly property int maxPeeks: 2             // cap the visible peek "layers" so the stack stays compact
    readonly property int stackSpacing: Theme.gap // gap between cards when expanded
    readonly property int visiblePeeks: Math.max(0, Math.min(items.length - 1, maxPeeks))
    readonly property int fadeDur: 180            // crossfade duration

    // ---- card height bookkeeping ----
    // Cards have variable height (body text + actions), so positions /
    // implicitHeight derive from per-card reports. Stale trailing entries
    // are harmless — every accessor is bounded by items.length.
    property var heights: []
    function _setHeight(i, h) {
        const arr = heights.slice();
        while (arr.length <= i)
            arr.push(0);
        if (arr[i] === h)
            return;
        arr[i] = h;
        heights = arr;
    }

    readonly property int topHeight: heights[0] || 0
    readonly property int collapsedHeight: topHeight + visiblePeeks * peekHeight
    readonly property int expandedHeight: {
        let h = topHeight;
        for (let i = 1; i < items.length; i++)
            h += stackSpacing + (heights[i] || 0);
        return h;
    }

    // ---- delayed layout snap ----
    // On hover-in, snap implicitHeight to expanded immediately so the cards
    // have room to fade in. On hover-out, KEEP implicitHeight at expanded
    // until the cards finish fading — otherwise the surrounding ColumnLayout
    // would shrink underneath them and they'd disappear mid-fade.
    property bool _layoutExpanded: expanded
    onExpandedChanged: {
        if (expanded) {
            collapseTimer.stop();
            _layoutExpanded = true;
        } else {
            collapseTimer.restart();
        }
    }
    Timer {
        id: collapseTimer
        interval: root.fadeDur
        onTriggered: root._layoutExpanded = false
    }

    implicitHeight: _layoutExpanded ? expandedHeight : collapsedHeight

    // Suppress Behavior animations on initial layout — without this the
    // first-frame binding evaluations would all animate, producing a brief
    // settle on every panel open.
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => root._ready = true)

    // group-wide entrance animation, pulsed by the panel
    opacity: 1
    transform: Translate {
        id: slide
        y: 0
    }
    SequentialAnimation {
        id: enterAnim
        PauseAnimation {
            duration: root.staggerIndex * 45
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: slide
                property: "y"
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }
    onAnimateIn: {
        opacity = 0;
        slide.y = 8;
        enterAnim.restart();
    }

    // ---- top card (always visible) ----
    NotificationCard {
        id: topCard
        notification: root.items[0]
        mode: "center"
        x: 0
        y: 0
        width: root.width
        z: 3
        onImplicitHeightChanged: root._setHeight(0, topCard.implicitHeight)
        Component.onCompleted: root._setHeight(0, topCard.implicitHeight)
    }

    // ---- count badge ----
    // Small accent pill overlapping the top-right corner of the app icon
    // (same x/y geometry the NotificationCard uses for the icon: 14px padding,
    // 13px top, 34px square). Hidden once the group is fanned out — each
    // card is its own item then, so the count loses meaning.
    Rectangle {
        id: countBadge
        visible: root.items.length > 1
        height: 16
        width: Math.max(16, badgeText.implicitWidth + 8)
        radius: 8
        color: Theme.accent
        x: 14 + 34 + 3 - width   // overshoot the icon's right edge by 3px
        y: 13 - 4                // overshoot the icon's top edge by 4px
        z: 4
        antialiasing: true
        opacity: root.expanded ? 0 : 1
        Behavior on opacity {
            enabled: root._ready
            NumberAnimation {
                duration: root.fadeDur
            }
        }

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.items.length
            font.family: Theme.fonts.sans
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Theme.accentInk
        }
    }

    // ---- stub stack hints (visible when collapsed) ----
    // Lightweight Rectangles, NOT NotificationCards. Each stub is a short strip
    // with rounded bottom corners only; straight top corners butt cleanly
    // against the bottom edge of the layer above (top card or previous
    // stub). Each layer is inset horizontally so the stack reads as a
    // deck of cards. They paint at negative z so they sit below the top
    // card; the top card's z=3 keeps it on top.
    Repeater {
        model: root.visiblePeeks

        delegate: Rectangle {
            required property int index
            readonly property int depth: index + 1   // 1, 2, ...

            x: depth * root.peekInset
            width: root.width - 2 * depth * root.peekInset
            y: root.topHeight + (depth - 1) * root.peekHeight
            height: root.peekHeight + 2  // small bottom buffer so the radius reads cleanly

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.rLg
            bottomRightRadius: Theme.rLg
            color: Theme.bg
            antialiasing: true

            z: -depth
            opacity: root.expanded ? 0 : 1
            Behavior on opacity {
                enabled: root._ready
                NumberAnimation {
                    duration: root.fadeDur
                }
            }
        }
    }

    // ---- trailing cards (visible when expanded) ----
    // Real NotificationCards in a normal vertical layout. Crossfaded with the stubs
    // above. A tiny y-translate gives the fade some directional motion
    // without paying for a per-card y Behavior (the cards' actual positions
    // are layout-driven and constant).
    ColumnLayout {
        x: 0
        y: root.topHeight + root.stackSpacing
        width: root.width
        spacing: root.stackSpacing
        z: 1

        Repeater {
            // Integer-count model — same VDMListDelegateDataType reason as
            // the panel / toast / top-level group Repeaters.
            model: Math.max(0, root.items.length - 1)

            delegate: NotificationCard {
                id: trailCard
                required property int index
                readonly property int idx: trailCard.index + 1

                notification: root.items[idx]
                mode: "center"
                Layout.fillWidth: true

                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                enabled: root.expanded

                transform: Translate {
                    id: trailSlide
                    y: root.expanded ? 0 : -6
                    Behavior on y {
                        enabled: root._ready
                        NumberAnimation {
                            duration: root.fadeDur
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    enabled: root._ready
                    NumberAnimation {
                        duration: root.fadeDur
                    }
                }

                onImplicitHeightChanged: root._setHeight(idx, trailCard.implicitHeight)
                Component.onCompleted: root._setHeight(idx, trailCard.implicitHeight)
            }
        }
    }
}
