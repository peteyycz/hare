pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// PowerService — public contract
// =============================================================================
// Properties: none.
// Methods:
//   shutdown() — power off the machine
//   reboot()   — restart the machine
//   suspend()  — sleep
//   lock()     — lock the current session (logind signal)
//   logout()   — exit the Hyprland session
// Signals: none.
//
// Backend: shells out to systemctl / loginctl / hyprctl. A future native impl
// could call logind over D-Bus directly; it must expose the same five methods.
// =============================================================================
Singleton {
    id: root

    function shutdown() {
        _run(["systemctl", "poweroff"]);
    }
    function reboot() {
        _run(["systemctl", "reboot"]);
    }
    function suspend() {
        _run(["systemctl", "suspend"]);
    }
    function lock() {
        _run(["loginctl", "lock-session"]);
    }
    function logout() {
        _run(["hyprctl", "dispatch", "exit"]);
    }

    function _run(cmd) {
        proc.command = cmd;
        proc.running = true;
    }

    Process {
        id: proc
    }
}
