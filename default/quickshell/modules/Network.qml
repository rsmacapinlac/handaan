// Network: does my connected network have internet access?
//
// A green globe means internet access; a peach globe pulses when a network
// is connected without it. Disconnected is a steady gray globe; a connected
// network with unverified internet status takes no space.
// The same bare glyph size as Updates and the Battery/Updates pulse keep one
// visual vocabulary. Pulsing at peach and sharing the motion channel are
// deliberate exceptions recorded in docs/quickshell-widgets.md.
//
// Networking is a process-wide service, read through bindings so every bar
// observes the same answer without launching per-monitor checks. NetworkManager
// owns the connectivity probe and its timing; no network names are persisted.

import QtQuick
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

    // Both can be connected at once. Report the attached transports without
    // claiming which one carries the default route or a particular request.
    readonly property string connectionDetail: {
        const devices = networkService.devices.values;
        const wifi = devices.some(device => device.connected && device.type === DeviceType.Wifi);
        const wired = devices.some(device => device.connected && device.type === DeviceType.Wired);
        if (wifi && wired)
            return "Wi-Fi and wired connections";
        if (wifi)
            return "Wi-Fi connection";
        if (wired)
            return "Wired connection";
        return "Network connected";
    }

    active: !connected || verified
    implicitWidth: icon.implicitWidth

    Tooltip {
        anchorItem: root
        open: root.active && hover.containsMouse
        text: !root.connected ? "Not connected" : (root.online ? "Internet reachable" : "No internet access")
        detail: root.connected ? root.connectionDetail + (root.connectivity === NetworkConnectivity.Portal
            ? "\nSign-in required" : "") : ""
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -Style.widgetPadding
        enabled: root.active
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.run("kitty --title 'Network' -e nmtui")
    }

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
