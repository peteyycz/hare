pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// =============================================================================
// NotificationService — public contract
// =============================================================================
// Properties:
//   list      : NotificationServer model — persistent notifications (the center)
//   toasts    : list — currently visible transient toasts
//   times     : map<id, Date> — arrival times for relative-age labels
//   dnd       : bool (read/write) — do-not-disturb / Focus
//   panelOpen : bool (read/write) — true while the center is open;
//               suppresses toasts
// Methods:
//   clearAll()
//   dismiss(notification)
//   hasDefault(notification) : bool
//   invokeDefault(notification)
//   invokeAction(action)
//   accent(notification)     : color
//   age(notification)         : string
// Signals: none (consumers bind to the reactive properties).
//
// Backend: hosts the freedesktop notification server for the whole shell.
// Per-screen panels and the toast layer are thin views over this singleton.
//
// NOTE: only one process may own org.freedesktop.Notifications — a running
// mako/dunst will prevent this server from registering.
Singleton {
    id: root

    // persistent notifications shown in the center (NotificationServer model)
    readonly property var list: server.trackedNotifications
    // notifications currently shown as transient toasts
    property var toasts: []

    // arrival times keyed by notification id (for relative-age labels) and a
    // coarse clock the cards bind to so "3m" ages without per-card timers
    property var times: ({})
    property double now: Date.now()
    // set by the center panels so toasts can step aside while one is open
    property bool panelOpen: false
    // Focus / Do-Not-Disturb: suppresses transient toasts while on (driven by
    // the Control Center "Focus" toggle); notifications still land in the
    // center, and Critical urgency still pops through.
    property bool dnd: false

    NotificationServer {
        id: server

        keepOnReload: true          // survive shell hot-reload (keep registration + list)
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: function (n) {
            root.times[n.id] = Date.now();

            // Mark `tracked` SYNCHRONOUSLY on the DBus frame. Quickshell
            // destroys the underlying Notification very shortly after this
            // handler returns, so deferring this write into a Qt.callLater
            // (where `n` is already gone) silently no-ops — the server
            // never adds the notification to `trackedNotifications`, and
            // the center stays empty even for persistent notifications.
            // The cascading-binding crash that originally motivated the
            // deferral can't re-fire either: the Repeaters that consume
            // `trackedNotifications` use integer-count models, so the
            // VDMListDelegateDataType incubation path isn't taken.
            n.tracked = !n.transient;

            // Snapshot the display data so transient notifications (which
            // are NOT tracked and therefore get reaped) still render with
            // real content in the toast layer. The toast push is the only
            // mutation we still defer — it isn't load-bearing for the
            // notification's lifetime, only for the Repeater's model.
            const snapshot = {
                id: n.id,
                summary: n.summary ?? "",
                body: n.body ?? "",
                appName: n.appName ?? "",
                appIcon: n.appIcon ?? "",
                image: n.image ?? "",
                urgency: n.urgency,
                transient: n.transient ?? false,
                expireTimeout: n.expireTimeout ?? -1,
                actions: (n.actions ?? []).map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    _src: a
                })),
                _src: n
            };
            Qt.callLater(() => {
                if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                    root.pushToast(snapshot);
            });
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    // Per-toast auto-dismiss. Owned by the singleton (not the toast delegate) so
    // each toast counts down on its own clock: the toast list reassigns on every
    // push/drop, which rebuilds the view's delegates — a delegate-side timer
    // would restart for every toast whenever the set changed.
    Component {
        id: toastTimer
        Timer {
            property var notif
            repeat: false
            running: true
            onTriggered: {
                root.dropToast(notif);
                destroy();
            }
        }
    }

    function pushToast(n) {
        root.toasts = root.toasts.concat([n]);
        // Critical toasts are sticky (no auto-dismiss); others honour the app's
        // requested timeout, falling back to 5s.
        if (n?.urgency !== NotificationUrgency.Critical) {
            const e = n?.expireTimeout ?? 0;
            toastTimer.createObject(root, {
                notif: n,
                interval: e > 0 ? e : 5000
            });
        }
    }
    function dropToast(n) {
        // Match by `id`, NOT object identity. Snapshots are plain JS objects
        // stored on a QML `var` property; the engine wraps them in a QVariant
        // and the read-back reference doesn't `===` the original we stored —
        // so `t !== n` was true for every entry and the toast never left.
        if (!n)
            return;
        const id = n.id;
        root.toasts = root.toasts.filter(t => t?.id !== id);
    }
    // Toast entries are SNAPSHOTS (plain JS objects with `_src` pointing at
    // the underlying Notification QObject); center entries are real
    // Notification QObjects from `server.trackedNotifications`. Helpers
    // below accept either — `_src ?? n` peels off the snapshot wrapper so
    // dismiss / invoke land on the live server-side object whenever it's
    // still around.
    function _live(n) {
        return n?._src ?? n;
    }

    function dismiss(n) {
        dropToast(n);
        const src = _live(n);
        if (src && typeof src.dismiss === "function") {
            try {
                src.dismiss();
            } catch (e) {}
        }
    }
    function clearAll() {
        const arr = (root.list?.values ?? []).slice();  // copy: dismiss mutates the model
        for (const n of arr)
            n.dismiss();
        root.toasts = [];
    }
    // Invoke the implicit "default" action (body-click) if the notification has
    // one. Does NOT dismiss — only the × button closes a card.
    function invokeDefault(n) {
        invokeAction((n?.actions ?? []).find(x => x.identifier === "default"));
    }
    // Invoke a single action (used by the action chips in NotificationCard). Accepts
    // both snapshot action wrappers and live NotificationAction QObjects.
    function invokeAction(a) {
        if (!a)
            return;
        const src = a._src ?? a;
        if (typeof src.invoke === "function") {
            try {
                src.invoke();
            } catch (e) {}
        }
    }
    // does this notification carry an implicit body-click action?
    function hasDefault(n) {
        return (n?.actions ?? []).some(x => x.identifier === "default");
    }
    function accent(n) {
        return (n?.urgency === NotificationUrgency.Critical) ? Theme.error : Theme.accent;
    }

    // relative age label, e.g. "now" / "3m" / "2h" / "1d"
    function age(n) {
        const t = root.times[n?.id];
        if (!t)
            return "now";
        const s = Math.max(0, (root.now - t) / 1000);
        if (s < 45)
            return "now";
        if (s < 3600)
            return Math.round(s / 60) + "m";
        if (s < 86400)
            return Math.round(s / 3600) + "h";
        return Math.round(s / 86400) + "d";
    }
}
