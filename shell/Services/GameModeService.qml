pragma Singleton

import Quickshell
import Quickshell.Io

// Hyprland "game mode": strips the expensive compositor effects (animations,
// blur, shadows, gaps, rounding) and allows tearing for lower latency while
// gaming. Mirrors the Caelestia shell's gamemode. State lives here (a singleton)
// so every per-screen bar button stays in sync; turning it off runs
// `hyprctl reload` to restore everything from the user's config.
Singleton {
    id: root

    property bool enabled: false

    Process {
        id: proc
    }

    function apply() {
        proc.command = root.enabled ? ["hyprctl", "--batch", "keyword animations:enabled 0 ; keyword decoration:shadow:enabled 0 ; keyword decoration:blur:enabled 0 ; keyword general:gaps_in 0 ; keyword general:gaps_out 0 ; keyword general:border_size 1 ; keyword decoration:rounding 0 ; keyword general:allow_tearing 1"] : ["hyprctl", "reload"];
        proc.running = true;
    }

    onEnabledChanged: apply()
}
