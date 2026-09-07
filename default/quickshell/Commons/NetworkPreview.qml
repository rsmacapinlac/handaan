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
    readonly property var devices: ({values: root.mode === "disconnected" ? [] : [
        {connected: true, type: root.transport === "wifi" ? DeviceType.Wifi : DeviceType.Wired}
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
