pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// PowerProfileService — public contract
// =============================================================================
// Properties (read-only):
//   available : bool   — powerprofilesctl is installed
//   active    : string — current profile name (e.g. "performance")
//   profiles  : list<string> — profiles the daemon advertises (e.g.
//                              ["performance", "balanced", "power-saver"])
// Methods:
//   set(profile: string)
//   has(profile: string) : bool
// Signals: none.
//
// Backend: shells out to `powerprofilesctl`. State is kept fresh by re-running
// `get` after every `set` and on a slow background timer; `list` only runs
// once unless the daemon is restarted with a different profile set. A future
// native impl could call power-profiles-daemon over D-Bus directly; it must
// expose the same `available` / `active` / `profiles` + `set()` / `has()`.
//
// Named `PowerProfileService` (not `PowerProfiles`) because
// `Quickshell.Services.UPower` already exports a `PowerProfiles` singleton
// with a different shape; `BatteryButton.qml` imports UPower for
// `displayDevice`, so an unqualified `PowerProfiles` there would resolve to
// Quickshell's type and our `available` would read back as undefined.
Singleton {
    id: root

    property bool available: false
    property string active: ""
    // List of profile name strings, e.g. ["performance", "balanced", "power-saver"]
    property var profiles: []

    function set(profile) {
        if (!available || !profile)
            return;
        // Remember which profile we asked for so onExited can phrase the
        // toast — getProc may not have re-read `active` yet by then.
        root._pendingProfile = profile;
        setProc.command = ["powerprofilesctl", "set", profile];
        setProc.running = true;
    }

    function has(profile) {
        return profiles.indexOf(profile) >= 0;
    }

    // "power-saver" → "Power Saver", "performance" → "Performance"
    function _label(p) {
        return (p ?? "").split("-").map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(" ");
    }

    property string _pendingProfile: ""

    Process {
        id: probeProc
        // Declarative `running: true` (matches backlightQuery in
        // ControlCenterPanel) so the probe fires the moment the singleton is
        // constructed, before any user click can race it.
        running: true
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null && echo y || echo n"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim() === "y";
                if (root.available) {
                    listProc.running = true;
                    getProc.running = true;
                }
            }
        }
    }

    Process {
        id: listProc
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Lines like "  performance:" or "* power-saver:" — strip
                // the leading "* " active marker and the trailing colon.
                const profs = [];
                for (const line of text.split("\n")) {
                    const m = line.match(/^\s*\*?\s*([a-z-]+):\s*$/);
                    if (m)
                        profs.push(m[1]);
                }
                root.profiles = profs;
            }
        }
    }

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim()
        }
    }

    Process {
        id: setProc
        onExited: (exitCode, exitStatus) => {
            // Re-read the active profile so the panel's "on" highlight
            // catches up, and emit a transient toast confirming the switch.
            // The toast is routed through notify-send → hare's own
            // notification server, so it respects DND / Focus.
            if (exitCode === 0 && root._pendingProfile) {
                notifyProc.command = ["notify-send", "-a", "hare", "-t", "3000", "Power Mode", root._label(root._pendingProfile) + " applied"];
                notifyProc.running = true;
            }
            root._pendingProfile = "";
            getProc.running = true;
        }
    }

    Process {
        id: notifyProc
    }

    // Background re-check in case something else (battery hold, tuned, …)
    // changes the profile out from under us.
    Timer {
        interval: 30000
        repeat: true
        running: root.available
        onTriggered: getProc.running = true
    }
}
