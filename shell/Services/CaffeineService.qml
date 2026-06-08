pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// CaffeineService — public contract
// =============================================================================
// Properties (read-only):
//   active : bool — true while the idle/sleep inhibitor is held
// Methods:
//   toggle()
//   setActive(b: bool)
// Signals: none.
//
// Backend: holds a `systemd-inhibit --what=idle:sleep sleep infinity` process
// alive while active. A future native impl could call into logind directly via
// D-Bus; it must expose the same `active` + `toggle()` / `setActive()`.
// =============================================================================
Singleton {
    id: root

    readonly property bool active: proc.running

    function toggle() {
        proc.running = !proc.running;
    }

    function setActive(b) {
        proc.running = !!b;
    }

    Process {
        id: proc
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=hare", "--why=Caffeine", "sleep", "infinity"]
    }
}
