pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// NightLightService — public contract
// =============================================================================
// Properties (read-only):
//   active      : bool — true while the night-light daemon is held running
//   temperature : int  — colour temperature in K (defaults to 3500)
// Methods:
//   toggle()
//   setActive(b: bool)
// Signals: none.
//
// Backend: holds `hyprsunset -t <K>` alive while active. A future native impl
// must expose the same `active` / `temperature` + `toggle()` / `setActive()`.
// =============================================================================
Singleton {
    id: root

    readonly property bool active: proc.running
    property int temperature: 3500

    function toggle() {
        proc.running = !proc.running;
    }

    function setActive(b) {
        proc.running = !!b;
    }

    Process {
        id: proc
        command: ["hyprsunset", "-t", root.temperature.toString()]
    }
}
