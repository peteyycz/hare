pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Single freedesktop notification server for the whole shell, plus the bit of
// state the UI needs on top of it: the persistent list (the center), the
// transient toast queue, per-notification arrival times (the spec gives us no
// timestamp), and helpers for dismiss / actions. Per-screen panels and the
// toast layer are thin views over this.
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
            n.tracked = !n.transient;   // transient hints toast only, don't persist
            // In Focus/DND, keep collecting into the center but skip the toast —
            // except Critical, which always pops through.
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.pushToast(n);
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
        root.toasts = root.toasts.filter(t => t !== n);
    }
    function dismiss(n) {
        dropToast(n);
        if (n)
            n.dismiss();
    }
    function clearAll() {
        const arr = (root.list?.values ?? []).slice();  // copy: dismiss mutates the model
        for (const n of arr)
            n.dismiss();
        root.toasts = [];
    }
    // Invoke the implicit "default" action (body-click) if the notification has
    // one. Does NOT dismiss — the caller decides: a clicked toast is "handled"
    // and removed from the center, a center card stays until its × is pressed.
    function invokeDefault(n) {
        const a = (n?.actions ?? []).find(x => x.identifier === "default");
        if (a)
            a.invoke();
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
