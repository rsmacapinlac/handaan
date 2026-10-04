// In-memory visual review only; never changes NetworkManager state.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    property bool enabled: false
    property string mode: "live"
    property string transport: "wifi"
    // A mock interface name and address, so a preview exercises the tooltip's
    // address line too. Kept obviously fake -- a preview that showed a
    // plausible address would be hard to tell from the live one in a
    // screenshot taken to review it.
    readonly property string interfaceName: root.transport === "wifi" ? "wlan0" : "eth0"
    readonly property string address: "203.0.113.10"
    readonly property var addresses: ({[root.interfaceName]: root.address})
    readonly property var devices: ({values: root.mode === "disconnected" ? [] : [
        {connected: true, name: root.interfaceName, type: root.transport === "wifi" ? DeviceType.Wifi : DeviceType.Wired}
    ]})
    readonly property bool canCheckConnectivity: true
    readonly property bool connectivityCheckEnabled: true
    readonly property int connectivity: {
        if (root.mode === "online") return NetworkConnectivity.Full;
        if (root.mode === "portal") return NetworkConnectivity.Portal;
        if (root.mode === "unknown") return NetworkConnectivity.Unknown;
        return NetworkConnectivity.Limited;
    }

    IpcHandler {
        target: "networkPreview"

        function show(mode: string, transport: string): string {
            if (!["live", "online", "offline", "portal", "disconnected", "unknown"].includes(mode))
                return "Expected live, online, offline, portal, disconnected, or unknown";
            if (!["wifi", "wired"].includes(transport))
                return "Expected wifi or wired";
            root.mode = mode;
            root.transport = transport;
            root.enabled = mode !== "live";
            expiry.restart();
            return root.enabled ? "Preview: " + mode + " / " + transport + " (expires in 10 minutes)" : "Live network status restored";
        }
    }

    Timer {
        id: expiry
        interval: 10 * 60 * 1000
        onTriggered: {
            root.enabled = false;
            root.mode = "live";
        }
    }
}
