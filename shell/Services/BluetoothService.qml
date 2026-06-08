pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// =============================================================================
// BluetoothService — public contract
// =============================================================================
// Properties (read-only):
//   adapter          : BluetoothAdapter? — Quickshell.Bluetooth default adapter
//   enabled          : bool
//   discovering      : bool
//   devices          : list<BluetoothDevice>
//   connectedDevices : list<BluetoothDevice>
//   sortedDevices    : list<BluetoothDevice> (connected > paired > available,
//                                              then alphabetical)
//   busyAddress      : string — non-empty while a connect/disconnect is
//                               in flight on that device's address
//   lastError        : string
// Methods:
//   refresh(), toggleAdapter(),
//   connect(device), disconnect(device), pair(device)
// Signals: none (consumers bind to reactive properties).
//
// Backend: reads via Quickshell.Bluetooth, writes via `bluetoothctl`. The
// shell-out for writes avoids depending on which methods Quickshell exposes
// on BluetoothDevice and stays consistent with NetworkService's nmcli split.
// A future native impl could call BlueZ over D-Bus directly.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    readonly property var devices: Bluetooth.devices?.values ?? []
    readonly property var connectedDevices: root.devices.filter(d => d?.connected ?? false)

    // sorted: connected → paired → available, then alphabetical inside each bucket
    readonly property var sortedDevices: {
        const arr = root.devices.slice();
        arr.sort((a, b) => {
            const sa = root._rank(a);
            const sb = root._rank(b);
            if (sa !== sb)
                return sa - sb;
            return ((a?.name ?? "") + "").localeCompare((b?.name ?? "") + "");
        });
        return arr;
    }

    function _rank(d) {
        if (d?.connected)
            return 0;
        if (d?.paired)
            return 1;
        return 2;
    }

    // Address of the device whose connect/disconnect/pair is in-flight — used
    // by the row to show the "…" busy state. Cleared on the process exit.
    property string busyAddress: ""
    property string lastError: ""

    function refresh() {
        if (!adapter)
            return;
        adapter.discovering = true;
        // BlueZ discovery is power-hungry; auto-stop so the user can't leave
        // it running by forgetting to close the panel.
        scanStop.restart();
    }

    Timer {
        id: scanStop
        interval: 20000
        onTriggered: if (root.adapter)
            root.adapter.discovering = false
    }

    function toggleAdapter() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function connect(d) {
        if (!d)
            return;
        root.busyAddress = d.address ?? "";
        root.lastError = "";
        // Unpaired devices need to be paired first; bluetoothctl pair will
        // bond + trust + (usually) connect in one shot.
        actProc.command = d.paired ? ["bluetoothctl", "connect", d.address] : ["bluetoothctl", "pair", d.address];
        actProc.running = true;
    }

    function disconnect(d) {
        if (!d)
            return;
        root.busyAddress = d.address ?? "";
        root.lastError = "";
        actProc.command = ["bluetoothctl", "disconnect", d.address];
        actProc.running = true;
    }

    Process {
        id: actProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.lastError = text.trim();
            }
        }
        onExited: root.busyAddress = ""
    }
}
