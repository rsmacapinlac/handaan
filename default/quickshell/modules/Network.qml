// Network indicator.
//
// The design record is docs/quickshell/widgets/network-indicator.md -- the
// question this answers, why it holds a share of the motion channel the design
// language rations, and what hover adds. Only the implementation reasoning is
// here, and most of it sits at the declarations below.
//
// Networking is a process-wide service, read through bindings so every bar
// observes the same answer without launching a check per monitor.
// NetworkManager owns the connectivity probe and its timing; no network names
// are persisted.

import QtQuick
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "network"

    property var networkService: NetworkPreview.enabled ? NetworkPreview : Networking
    readonly property bool connected: networkService.devices.values.some(device => device.connected)
    readonly property int connectivity: networkService.connectivity
    // Disabled checks can report Full without probing. That is not evidence
    // of internet access, so treat it like an unknown result.
    readonly property bool verified: networkService.canCheckConnectivity
        && networkService.connectivityCheckEnabled
        && connectivity !== NetworkConnectivity.Unknown
    readonly property bool online: connected && connectivity === NetworkConnectivity.Full
    readonly property bool needsAttention: active && connected && !online
    readonly property real pulseScale: 1.12

    readonly property var connectedDevices: networkService.devices.values.filter(device => device.connected)

    // The transport, on the card. Both can be connected at once, and the card
    // names both rather than picking one: which of them carries the default
    // route is not something NetworkManager is asked here, so claiming it
    // would be an invention.
    readonly property string transportLabel: {
        const wifi = connectedDevices.some(device => device.type === DeviceType.Wifi);
        const wired = connectedDevices.some(device => device.type === DeviceType.Wired);
        if (wifi && wired)
            return "Wi-Fi+Wired";
        if (wifi)
            return "Wi-Fi";
        if (wired)
            return "Wired";
        return "";
    }

    // Addresses by interface name. NetworkDevice carries .name and .address,
    // but .address is the MAC -- the IP is not on the service at all, so it
    // comes from `ip` below.
    property var addresses: ({})

    // The address on the card, which is the one the card can be honest about.
    // With both transports up there are two, and picking one would claim it
    // carries the default route -- the same claim the transport label above
    // refuses to make. The tooltip lists both instead.
    readonly property string cardAddress: {
        if (root.connectedDevices.length !== 1)
            return "";
        return root.addresses[root.connectedDevices[0].name] ?? "";
    }

    // The address is on the glance layer now, so it is read without being
    // asked for: no interaction may be required to read a widget. `ip` reads
    // the kernel's own table and puts no traffic on the network, so this is
    // still a widget that starts no probe of its own.
    function refreshAddresses() {
        if (NetworkPreview.enabled) {
            root.addresses = NetworkPreview.addresses;
            return;
        }
        addressQuery.running = false;
        addressQuery.running = true;
    }

    // A lease renewal or a VPN coming up changes the address without changing
    // the device list, and a stale address on the bar is a wrong one rather
    // than an old one.
    Timer {
        interval: 60 * 1000
        running: root.connected
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAddresses()
    }

    onConnectedDevicesChanged: root.refreshAddresses()

    Process {
        id: addressQuery

        // Every interface in one read, rather than one call per device: with
        // both transports up the tooltip wants both, and two processes racing
        // to fill one map is a worse answer than one that arrives whole.
        command: ["ip", "-j", "-4", "addr"]

        stdout: StdioCollector {
            onStreamFinished: {
                var found = ({});
                try {
                    for (const link of JSON.parse(this.text)) {
                        // An interface can carry several v4 addresses; the
                        // secondaries are aliases of the first, so naming them
                        // would spend a line each on one fact.
                        const entry = (link.addr_info ?? []).find(address => address.scope === "global" && !address.secondary);
                        if (entry)
                            found[link.ifname] = entry.local;
                    }
                } catch (error) {
                    // No address yet, or `ip` said something unexpected. The
                    // tooltip renders that by falling back to interface names.
                    found = ({});
                }
                root.addresses = found;
            }
        }
    }

    // The hover layer: the address against the interface carrying it, which is
    // the pairing the card cannot make when both transports are up.
    readonly property string hoverDetail: {
        if (!root.connected)
            return "";
        const lines = root.connectedDevices.map(device => {
            const address = root.addresses[device.name] ?? "";
            return address !== "" ? address + "  \u00b7  " + device.name : device.name;
        });
        if (root.connectivity === NetworkConnectivity.Portal)
            lines.push("Sign-in required");
        return lines.join("\n");
    }

    active: !connected || verified
    // A card carrying one line: which transport is attached. See
    // docs/quickshell/widgets/network-indicator.md.
    implicitWidth: card.implicitWidth

    Tooltip {
        anchorItem: root
        open: root.active && hover.containsMouse
        text: !root.connected ? "Not connected" : (root.online ? "Internet reachable" : "No internet access")
        detail: root.hoverDetail
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -Style.widgetPadding
        enabled: root.active
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onContainsMouseChanged: if (containsMouse) root.refreshAddresses()
        onClicked: root.run("kitty --title 'Network' -e nmtui")
    }

    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical

        // The Clock's arrangement: the qualifier above, muted, and the figure
        // you would read off and use below it at full contrast.
        lineOne: root.transportLabel
        lineOneColor: Theme.barTextMuted
        // Small on a side bar, as the Clock's first line is. "Wi-Fi+Wired" is
        // 73px of the column's 78 at that size and 86px at the larger one, so
        // the size is what lets the two-transport case say both names.
        lineOneSize: root.vertical ? Style.fontSizeSmall : Style.fontSize

        lineTwo: root.cardAddress
        lineTwoColor: root.foreground
        lineTwoSize: Style.fontSize
        // Shrunk to fit rather than elided: a short address draws at the
        // Clock's size, a long one loses a point or two, and none of them is
        // ever cut into a different address. "192.168.100.200" is the case
        // that needs it -- 117px of the column's 78 at this size.
        lineTwoFit: root.vertical

        Text {
            id: icon
            anchors.centerIn: parent
            // Nerd Font U+F0AC: globe. Escaped so the glyph survives text edits.
            text: "\uf0ac"
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * root.pulseScale)
            color: !root.connected ? Theme.barTextMuted : (root.online ? Theme.good : Theme.warning)
            opacity: root.active ? 1 : 0

            SequentialAnimation on scale {
                running: root.needsAttention
                loops: Animation.Infinite
                // Stop immediately on recovery or disconnect, even mid-pulse.
                onStopped: icon.scale = 1.0

                NumberAnimation {
                    to: root.pulseScale
                    duration: 620
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: 620
                    easing.type: Easing.InOutSine
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.animationFast
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
