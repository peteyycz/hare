pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// BrightnessService — public contract
// =============================================================================
// Properties (read-only):
//   available : bool   — true when an internal backlight is present
//   value     : real   — current brightness in [0, 1]; cosmetic default until
//                        a user gesture applies one (we don't read the live
//                        kernel value back)
// Methods:
//   set(v: real)       — apply brightness, clamped to [0, 1]
// Signals: none.
//
// Backend: probes /sys/class/backlight for an internal backlight and shells
// out to `brightnessctl set N%`. A future native impl must expose the same
// `available` / `value` properties and `set()` method.
// =============================================================================
Singleton {
    id: root

    property bool available: false
    property real value: 0.72

    function set(v) {
        const clamped = Math.max(0, Math.min(1, v));
        root.value = clamped;
        applyProc.command = ["sh", "-c", "brightnessctl set " + Math.round(clamped * 100) + "% || true"];
        applyProc.running = true;
    }

    Process {
        id: probeProc
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim().length > 0
        }
    }

    Process {
        id: applyProc
    }
}
