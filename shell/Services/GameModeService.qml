pragma Singleton

import Quickshell
import Quickshell.Io

// =============================================================================
// GameModeService — public contract
// =============================================================================
// Properties (read/write):
//   enabled : bool — set to toggle game mode on/off
// Methods: none (mutate `enabled` directly).
// Signals: none.
//
// Backend: Hyprland "game mode" — strips the expensive compositor effects
// (animations, blur, shadows, gaps, rounding) and allows tearing for lower
// latency while gaming. Turning it off runs `hyprctl reload` to restore the
// user's config. State lives in the singleton so every per-screen bar stays
// in sync. A future native impl must expose the same `enabled` property.
// =============================================================================
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
