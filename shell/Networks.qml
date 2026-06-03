pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi management via NetworkManager (nmcli). Quickshell 0.2.x has no native
// network service, so the singleton shells out: a periodic `device wifi list`
// keeps `networks` / `activeSsid` fresh, while `refresh()` / `connect()` /
// `disconnect()` / `toggleWifi()` are user-driven. Known-profile detection
// (`_knownSet`) lets the panel skip the password prompt for saved networks.
Singleton {
    id: root

    // [{ ssid, signal, security, active, known }], deduped + sorted (active
    // first, then by signal strength). Hidden (empty-SSID) APs are dropped.
    property var networks: []
    property string activeSsid: ""
    property bool scanning: false
    property bool wifiEnabled: true

    // Last connect attempt error message (cleared on next attempt).
    property string lastError: ""
    // SSID of the in-flight connect attempt — drives the row's "…" state.
    property string connectingSsid: ""

    // nmcli --terse uses ':' as the field separator and '\' to escape literal
    // ':' / '\' inside fields (e.g. SSIDs that contain colons).
    function _parseTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === '\\' && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (c === ':') {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function refresh() {
        scanning = true;
        rescanProc.running = true;
    }

    function connect(ssid, password) {
        if (!ssid)
            return;
        lastError = "";
        connectingSsid = ssid;
        connectProc.command = (password && password.length > 0) ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "device", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    function disconnect(ssid) {
        if (!ssid)
            return;
        disconnectProc.command = ["nmcli", "connection", "down", ssid];
        disconnectProc.running = true;
    }

    function toggleWifi() {
        toggleProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        toggleProc.running = true;
    }

    Process {
        id: listProc
        command: ["nmcli", "--terse", "--fields", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                let active = "";
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root._parseTerse(line);
                    if (f.length < 4)
                        continue;
                    const ssid = f[1];
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    const isActive = f[0] === "*";
                    if (isActive)
                        active = ssid;
                    out.push({
                        ssid: ssid,
                        signal: parseInt(f[2]) || 0,
                        security: f[3] || "",
                        active: isActive,
                        known: root._knownSet[ssid] === true
                    });
                }
                out.sort((a, b) => {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;
                    return b.signal - a.signal;
                });
                root.networks = out;
                root.activeSsid = active;
                root.scanning = false;
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: listProc.running = true
    }

    Process {
        id: connectProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.lastError = text.trim();
            }
        }
        onExited: {
            root.connectingSsid = "";
            knownProc.running = true;
            listProc.running = true;
        }
    }

    Process {
        id: disconnectProc
        onExited: listProc.running = true
    }

    Process {
        id: toggleProc
        onExited: {
            radioProc.running = true;
            listProc.running = true;
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "--terse", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    // Saved wifi connection profiles → mark known networks so the panel can
    // skip the password prompt (nmcli reuses the saved secret).
    property var _knownSet: ({})
    Process {
        id: knownProc
        command: ["nmcli", "--terse", "--fields", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = {};
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root._parseTerse(line);
                    if (f.length >= 2 && f[1] === "802-11-wireless")
                        set[f[0]] = true;
                }
                root._knownSet = set;
            }
        }
    }

    Component.onCompleted: {
        radioProc.running = true;
        knownProc.running = true;
        listProc.running = true;
    }

    // Background refresh so the list ages out gracefully even with no panel
    // open. The user-driven refresh button is the fast path.
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: listProc.running = true
    }
}
