pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// NetworkService — public contract
// =============================================================================
// Wi-Fi (read-only):
//   networks       : list of { ssid, signal, security, active, known }
//   activeSsid     : string
//   scanning       : bool
//   wifiEnabled    : bool
//   connectingSsid : string — non-empty while a connect() is in flight
//   lastError      : string — surfaced near the wifi list
// Wi-Fi methods:
//   refresh(), toggleWifi(), connect(ssid, password), disconnect(ssid)
//
// Ethernet (read-only):
//   ethernetDevice     : string — empty when no managed wired link exists
//   ethernetConnection : string — name of the active connection, if any
//   ethernetState      : "connected" | "unavailable" | …
//   ethernetBusy       : bool
//   ethernetError      : string
// Ethernet methods:
//   toggleEthernet()
//
// VPN (read-only):
//   vpns          : list of { name, type, active }
//   connectingVpn : string
//   vpnError      : string
// VPN methods:
//   connectVpn(name), disconnectVpn(name)
//
// Signals: none (consumers bind to the reactive properties).
//
// Backend: shells out to `nmcli`. A future native impl could call into
// NetworkManager over D-Bus; it must expose the same properties and methods.
Singleton {
    id: root

    // ---- Wi-Fi ----
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

    // ---- Ethernet ----
    // First managed ethernet device. Empty `ethernetDevice` means no link is
    // available to manage (either no ethernet hardware, or every ethernet
    // interface is `unmanaged` — e.g. docker bridges' veths).
    property string ethernetDevice: ""
    // "connected" | "disconnected" | "unavailable" (carrier down)
    property string ethernetState: ""
    property string ethernetConnection: ""
    property string ethernetError: ""
    property bool ethernetBusy: false

    // ---- VPN ----
    // [{ name, type, active }] — every saved VPN/WireGuard profile.
    property var vpns: []
    property string vpnError: ""
    // Name of the in-flight VPN connect/disconnect attempt.
    property string connectingVpn: ""

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

    function _isVpnType(t) {
        return t === "vpn" || t === "wireguard" || t === "tun";
    }

    function refresh() {
        scanning = true;
        rescanProc.running = true;
        deviceProc.running = true;
        connProc.running = true;
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

    function connectEthernet() {
        if (!ethernetDevice)
            return;
        ethernetError = "";
        ethernetBusy = true;
        ethernetActionProc.command = ["nmcli", "device", "connect", ethernetDevice];
        ethernetActionProc.running = true;
    }

    function disconnectEthernet() {
        if (!ethernetDevice)
            return;
        ethernetError = "";
        ethernetBusy = true;
        ethernetActionProc.command = ["nmcli", "device", "disconnect", ethernetDevice];
        ethernetActionProc.running = true;
    }

    function toggleEthernet() {
        if (ethernetState === "connected")
            disconnectEthernet();
        else
            connectEthernet();
    }

    function connectVpn(name) {
        if (!name)
            return;
        vpnError = "";
        connectingVpn = name;
        vpnActionProc.command = ["nmcli", "connection", "up", name];
        vpnActionProc.running = true;
    }

    function disconnectVpn(name) {
        if (!name)
            return;
        vpnError = "";
        connectingVpn = name;
        vpnActionProc.command = ["nmcli", "connection", "down", name];
        vpnActionProc.running = true;
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
            connProc.running = true;
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

    // ---- ethernet poll ----
    // First managed ethernet wins. NM marks docker veths / bridges as
    // `unmanaged`; filtering those keeps the panel showing only the real NIC.
    Process {
        id: deviceProc
        command: ["nmcli", "--terse", "--fields", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let dev = "";
                let st = "";
                let conn = "";
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root._parseTerse(line);
                    if (f.length < 4)
                        continue;
                    if (f[1] !== "ethernet")
                        continue;
                    const state = f[2];
                    if (state === "unmanaged")
                        continue;
                    dev = f[0];
                    // nmcli reports states like "connecting (configuring)" —
                    // collapse to the short forms the UI cares about.
                    if (state.indexOf("connected") === 0 && state !== "disconnected")
                        st = "connected";
                    else if (state === "unavailable")
                        st = "unavailable";
                    else
                        st = "disconnected";
                    conn = f[3];
                    break;
                }
                root.ethernetDevice = dev;
                root.ethernetState = st;
                root.ethernetConnection = conn;
            }
        }
    }

    Process {
        id: ethernetActionProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.ethernetError = text.trim();
            }
        }
        onExited: {
            root.ethernetBusy = false;
            deviceProc.running = true;
        }
    }

    // ---- connection list (known wifi + VPN profiles) ----
    // One pass over `connection show` populates the known-wifi lookup AND a
    // pending VPN list, then an active-connections pass merges the active
    // flag and publishes `vpns`. Holding the pending list off until the
    // active pass finishes avoids a one-frame flash where every VPN row
    // looks disconnected.
    property var _knownSet: ({})
    property var _pendingVpns: []
    Process {
        id: connProc
        command: ["nmcli", "--terse", "--fields", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const known = {};
                const vpnList = [];
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root._parseTerse(line);
                    if (f.length < 2)
                        continue;
                    if (f[1] === "802-11-wireless")
                        known[f[0]] = true;
                    else if (root._isVpnType(f[1]))
                        vpnList.push({
                            name: f[0],
                            type: f[1]
                        });
                }
                root._knownSet = known;
                root._pendingVpns = vpnList;
                activeProc.running = true;
            }
        }
    }

    Process {
        id: activeProc
        command: ["nmcli", "--terse", "--fields", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const activeNames = {};
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root._parseTerse(line);
                    if (f.length < 2)
                        continue;
                    if (root._isVpnType(f[1]))
                        activeNames[f[0]] = true;
                }
                root.vpns = root._pendingVpns.map(v => ({
                            name: v.name,
                            type: v.type,
                            active: activeNames[v.name] === true
                        }));
            }
        }
    }

    Process {
        id: vpnActionProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.vpnError = text.trim();
            }
        }
        onExited: {
            root.connectingVpn = "";
            connProc.running = true;
        }
    }

    Component.onCompleted: {
        radioProc.running = true;
        connProc.running = true;
        listProc.running = true;
        deviceProc.running = true;
    }

    // Background refresh so the list ages out gracefully even with no panel
    // open. The user-driven refresh button is the fast path.
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            listProc.running = true;
            deviceProc.running = true;
            connProc.running = true;
        }
    }
}
