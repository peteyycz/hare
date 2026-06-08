pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// ScreenRecorderService — public contract
// =============================================================================
// Properties (read-only):
//   recording : bool   — true while a recording is in progress
//   lastPath  : string — path of the most recent recording (set when start
//                        is invoked; not reset on stop)
// Methods:
//   toggle()           — start if idle, stop (SIGINT) if recording
//   start()
//   stop()
// Signals: none.
//
// Backend: spawns `wf-recorder -f <path>` and finalises with SIGINT (NOT a
// hard kill — wf-recorder must flush the file header on shutdown or the
// resulting MP4 is unplayable). A future native impl must preserve that
// graceful-stop semantic.
// =============================================================================
Singleton {
    id: root

    readonly property bool recording: proc.running
    property string lastPath: ""

    function toggle() {
        if (proc.running)
            root.stop();
        else
            root.start();
    }

    function start() {
        if (proc.running)
            return;
        const dir = (Quickshell.env("HOME") ?? "") + "/Videos";
        root.lastPath = dir + "/hare-" + Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss") + ".mp4";
        proc.command = ["sh", "-c", "mkdir -p \"$1\"; exec wf-recorder -f \"$2\" -c libx264 -p preset=fast -p crf=18 --pixel-format yuv420p", "sh", dir, root.lastPath];
        proc.running = true;
    }

    function stop() {
        if (!proc.running)
            return;
        proc.signal(2); // SIGINT — lets wf-recorder flush the file header
    }

    Process {
        id: proc
    }
}
