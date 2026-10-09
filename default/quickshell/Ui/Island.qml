// The bar's centre section. See docs/island/README.md.
//
// Not a widget and not a card: a widget is a fixed question in a fixed place
// that you read, and this is a place you act in, holding whatever is currently
// going on. docs/bar.md has why that difference is worth three sections rather
// than one design language.
//
// Drawn in the bar's own window so the cut-out grows into the expanded
// surface. The bar reserves the same strip at either size; see Bar.qml.
//
// The cut-out is always present, including when nothing is going on. That is
// the one thing on the bar that is permanent without answering a question, and
// it earns it by not being information: it is the handle, and settings are
// always reachable through it.
//
// The cut-out is two sections. Context, on the left, says what you are in: the
// focused window's app on this monitor, with its title too on the monitor that
// has focus, so the title is also how you tell which screen keys go to. A
// notification is an event and takes context while it lasts, then hands it
// back. Status, on the right, holds badges -- capture, media, backlog -- which
// never take turns, because each is something you must not lose sight of while
// something else is in context.
//
// Its notifications are the same set NotificationCenter puts on screen, read
// straight off `popups`. That is deliberate: the centre already decides what
// pops, for how long, what do-not-disturb holds back, what the lock screen
// suppresses, and that critical stays until dismissed. None of that is worth
// a second implementation here, and a second one would drift.
//
// The popups still appear as well. That contradicts this section's own rule
// that it is not a second place to say something the bar already says, and it
// is deliberate and temporary -- both run so they can be compared before one
// is retired, the way Waybar stayed installed beside the Quickshell bar. See
// docs/island/README.md.
//
// Clicking the cut-out expands it; clicking away collapses it. Moving the
// pointer does neither. Bar.qml handles outside clicks, including those on
// other windows, while controls inside the island keep their own actions.
//
// Only horizontal bars have one. What a side bar should do is open -- its
// centre is the middle of a screen edge and its budget is the card text column
// -- so rather than guess, this draws nothing when vertical.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

Item {
    id: root

    // Set by the bar. The island is a horizontal-bar thing for now.
    property bool vertical: false

    // The monitor this copy is drawn on, injected by the bar the same way
    // every widget's is: Variants builds one surface per screen, and the
    // expanded width is a proportion of the screen it opened on. This is
    // geometry, not state -- what the island *shows* stays session-wide, per
    // docs/island/README.md.
    property var screen: null

    // The expanded shape's width: Style.islandWidth, which its two columns
    // add up to. The screen is a ceiling rather than the source -- the width is
    // the same on every monitor, and this only stops an island being wider
    // than a display narrower than any here. Logical pixels, the space every
    // other size is in: the bar's own layer surface measures 1536 on a
    // 1.25-scaled 1920 panel.
    readonly property int expandedWidth: root.screen ? Math.min(Style.islandWidth, root.screen.width - Style.space(3) * 2) : Style.islandWidth

    // How much taller than the bar the window has to be to hold this. Read by
    // Bar.qml, which grows the window by it while keeping the reserved strip
    // at barSize so no window on the screen moves.
    readonly property int overflow: Math.max(0, root.implicitHeight - Style.barSize)

    // What the bar masks in, beyond the bar strip itself. Everything else in
    // the grown window is transparent and must not take the pointer.
    readonly property Item hitArea: shape

    // The player worth speaking for: whichever is actually playing, else the
    // first that exists, else none. Session-wide on purpose -- every monitor's
    // island is a view onto the same player, so this must not be per screen.
    readonly property var player: {
        const all = Mpris.players.values;
        for (var i = 0; i < all.length; i++) {
            if (all[i].isPlaying)
                return all[i];
        }
        return all.length > 0 ? all[0] : null;
    }

    readonly property bool hasMedia: root.player !== null

    // The newest thing on screen, or nothing. NotificationCenter keeps these
    // newest-first and drops them on its own schedule, so the island needs no
    // timer of its own.
    readonly property var notification: NotificationCenter.popups.length > 0 ? NotificationCenter.popups[0].record : null

    readonly property bool hasNotification: root.notification !== null

    // This copy's monitor. Focus is per screen even though the island's other
    // state is not: every copy reading Hyprland.activeToplevel alone would put
    // the same window on every monitor.
    readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : null

    // focusedMonitor is only learned from an event, so until focus first moves
    // after a restart this falls back to what the startup query said.
    readonly property bool focusedHere: {
        if (!root.monitor)
            return false;
        if (Hyprland.focusedMonitor)
            return Hyprland.focusedMonitor === root.monitor;
        return root.monitor.lastIpcObject.focused === true;
    }

    // The window this monitor last had focused, kept so a monitor that loses
    // focus still names what is on it. Typed, so it reads null once the
    // window closes rather than holding a dead object.
    property HyprlandToplevel recent: null

    Connections {
        target: Hyprland

        function onActiveToplevelChanged() {
            const t = Hyprland.activeToplevel;
            if (t && root.monitor && t.monitor === root.monitor)
                root.recent = t;
        }
    }

    // What is in front on this monitor: the focused window if it is here,
    // else the one this monitor last had, else Hyprland's own record of the
    // workspace's last window -- the only answer before anything has moved.
    //
    // Reads the workspace list for its side effect: Hyprland fetches it on
    // first read, and until it has, a monitor's activeWorkspace is a guess --
    // it named 3 while the screen showed 1. Workspaces.qml happens to read it
    // too, which is not something this should rely on.
    readonly property var window: {
        const ws = root.monitor ? root.monitor.activeWorkspace : null;
        if (!ws || Hyprland.workspaces.values.length === 0)
            return null;
        const active = Hyprland.activeToplevel;
        if (active && active.workspace === ws)
            return active;
        if (root.recent && root.recent.workspace === ws)
            return root.recent;
        const wins = ws.toplevels.values;
        const last = String(ws.lastIpcObject.lastwindow || "").replace(/^0x/, "");
        for (var i = 0; i < wins.length; i++) {
            if (wins[i].address === last)
                return wins[i];
        }
        return wins.length > 0 ? wins[0] : null;
    }

    // The app's own name from its desktop entry, else the tail of its app id.
    // Reading the entry count makes this re-run once entries finish loading,
    // which heuristicLookup alone would not.
    readonly property string appName: {
        if (!root.window || DesktopEntries.applications.values.length < 0)
            return "";
        const id = root.window.wayland ? root.window.wayland.appId : (root.window.lastIpcObject.class || "");
        if (id === "")
            return "";
        const entry = DesktopEntries.heuristicLookup(id);
        if (entry && entry.name !== "")
            return entry.name;
        const tail = id.split(".").pop();
        return tail.charAt(0).toUpperCase() + tail.slice(1);
    }

    // Only where focus is. Most titles end by naming their app, which context
    // already says, so that tail is cut.
    readonly property string windowTitle: {
        if (!root.focusedHere || !root.window)
            return "";
        var t = root.window.title;
        const name = root.appName.toLowerCase();
        if (name !== "" && t.toLowerCase().endsWith(name)) {
            const cut = Math.max(t.lastIndexOf(" — "), t.lastIndexOf(" – "), t.lastIndexOf(" - "));
            if (cut > 0)
                t = t.slice(0, cut);
        }
        return t === root.appName ? "" : t;
    }

    // An event outranks a state. When the notification goes, the window is
    // still underneath it.
    readonly property string context: root.hasNotification ? "notification" : (root.appName !== "" ? "window" : "none")

    // Whether anything is reading the camera, the microphone or the screen.
    // An app capturing shows up in PipeWire as an input stream; a screen share
    // through the portal as xdg-desktop-portal-hyprland's own node, whether or
    // not anything has started reading it yet. Recorders that use
    // wlr-screencopy directly never touch PipeWire and are not seen.
    readonly property bool capturing: {
        const nodes = Pipewire.nodes.values;
        for (var i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n.name.startsWith("xdph-streaming-"))
                return true;
            if (n.isStream && (n.type & PwNodeType.Source))
                return true;
        }
        return false;
    }

    // What the bell used to answer, folded in here: what is waiting that you
    // have not dealt with, and whether you will be told about the next thing.
    //
    // It is a badge rather than an occupant, and that distinction is the whole
    // of why. The occupants are things happening now and they take turns; a
    // backlog is not happening, it is outstanding, and it has to still be
    // there while something else is in the island. An occupant would vanish
    // the moment a notification arrived.
    //
    // Waiting means kept, not unseen: reading the history does not clear this,
    // only dismissing or clearing does. A badge that went away when you looked
    // would hide what you have not dealt with behind a door you have to
    // remember exists.
    readonly property bool quiet: NotificationCenter.doNotDisturb

    readonly property var kept: {
        var out = { critical: 0, normal: 0, low: 0 };
        for (var i = 0; i < NotificationCenter.history.length; i++)
            out[NotificationCenter.history[i].urgency] += 1;
        return out;
    }

    readonly property bool hasBacklog: NotificationCenter.history.length > 0 || root.quiet

    // What the island holds. A popup is the announcement; when it times out
    // the notification has not gone anywhere, it is kept -- so it is in here,
    // and opening the island is how you get back to it.
    //
    // All of them, not a sample. The island is where notifications live, so a
    // stack that stopped at three and said "more waiting" was telling you
    // there was somewhere else to go -- and there should not be.
    //
    // Size the viewport from the first four cards; the rest remain reachable
    // by scrolling. The pixel ceiling still protects against very tall cards.
    readonly property var stacked: NotificationCenter.history

    // Taken from the most urgent kept rather than the newest, so a chatty app
    // cannot bury a critical one. Peach is deliberately not used: it is
    // Network's and Battery's warning, and a notification is not a warning.
    readonly property color backlogTint: {
        if (root.kept.critical > 0)
            return Theme.critical;
        if (root.kept.normal > 0)
            return Theme.active;
        return Theme.barTextMuted;
    }

    // The cut-out's own height: the bar's thickness less the inset that keeps
    // the bar's surface visible around it.
    readonly property int cutoutHeight: Style.barSize - Style.space(2)

    property bool expanded: false

    onVerticalChanged: {
        if (root.vertical)
            root.expanded = false;
    }

    // Escape closes it, as it does the shell's dialogs. Bar.qml hands this
    // surface the keyboard while the island is open; this takes it.
    onExpandedChanged: {
        if (root.expanded) {
            root.forceActiveFocus();
        } else {
            root.armed = "";
            root.outputsOpen = false;
        }
    }

    // An armed action is let go before the island is, as the power menu does.
    Keys.onEscapePressed: {
        if (root.armed !== "")
            root.armed = "";
        else
            root.expanded = false;
    }

    // What you hear through and speak into: WirePlumber's defaults. Session
    // wide, like the player -- one machine has one output whichever monitor
    // you change it from.
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // A node's volume and mute read empty until something tracks it.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Outputs you could switch to: devices, not the apps playing into them.
    readonly property var sinks: {
        var out = [];
        const nodes = Pipewire.nodes.values;
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].isSink && !nodes[i].isStream && nodes[i].audio)
                out.push(nodes[i]);
        }
        return out;
    }

    function nodeName(node) {
        if (!node)
            return "";
        return node.description || node.nickname || node.name;
    }

    property bool outputsOpen: false

    // Connected devices only. Pairing and connecting belong to Blueman, which
    // the button beside the output opens; what the island lists is what you
    // can let go of, so with nothing connected there is nothing to show.
    readonly property var bluetoothConnected: {
        var out = [];
        const devices = Bluetooth.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                out.push(devices[i]);
        }
        return out;
    }

    // The power menu's actions, with its rule: what ends every open window
    // arms on the first click and acts on the second. The id waiting for its
    // second click, or "".
    property string armed: ""

    function act(action) {
        if (action.confirm && root.armed !== action.id) {
            root.armed = action.id;
            return;
        }
        root.armed = "";
        root.expanded = false;
        SessionControl.run(action.id);
    }

    // The keyboard's way in. Every copy hears it; only the focused monitor's
    // acts, so Super+Shift+N opens the island where you are working.
    Connections {
        target: IslandControl

        function onRequested(action) {
            if (!root.focusedHere || root.vertical)
                return;
            root.expanded = action === "toggle" ? !root.expanded : action === "open";
        }
    }

    // What context says: who is telling you something, else what you are in.
    // Detail is the expanded state's job.
    readonly property string contextText: {
        if (root.context === "notification")
            return root.notification.summary !== "" ? root.notification.summary : root.notification.appName;
        return root.appName;
    }

    // Critical is the one notification state drawn loudly, the same way the
    // card draws it.
    readonly property color contextTint: {
        if (root.context === "notification" && root.notification.urgency === "critical")
            return Theme.critical;
        return Theme.barText;
    }

    readonly property bool hasStatus: root.capturing || root.hasMedia || root.hasBacklog

    implicitWidth: shape.width
    // The shape's inset above it, and the same inset below. Both have to be
    // asked for: shape.y spends the first one, so a single inset here leaves
    // the island flush with the window's own bottom edge -- 4px of bar above
    // the expanded island and none under it. Collapsed this still measures
    // exactly barSize, so overflow stays 0 and the ordinary bar is untouched.
    implicitHeight: shape.height + Style.space(1) * 2
    visible: !root.vertical

    // A labelled control in the expanded half, for the two things that act on
    // the whole set rather than on one notification.
    component IslandChip: Rectangle {
        id: chip

        required property string label
        property bool on: false
        signal activated

        implicitWidth: chipText.implicitWidth + Style.space(4)
        implicitHeight: chipText.implicitHeight + Style.space(2)
        radius: Style.radius
        color: chip.on ? Theme.active : (chipHover.hovered ? Theme.surfaceHover : Theme.surface)
        border.width: Style.borderWidth
        border.color: chip.on ? Theme.active : Theme.border

        Text {
            id: chipText

            anchors.centerIn: parent
            text: chip.label
            color: chip.on ? Theme.barBackground : Theme.barText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
        }

        HoverHandler {
            id: chipHover
        }

        TapHandler {
            onTapped: chip.activated()
        }
    }

    // One control in the expanded half. Click, because this is the acting
    // layer -- the bar's rule is that click performs an action.
    component IslandButton: Text {
        id: button

        required property string glyph
        signal activated

        text: button.glyph
        color: button.enabled ? Theme.barText : Theme.barTextMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        Layout.alignment: Qt.AlignVCenter

        TapHandler {
            enabled: button.enabled
            onTapped: button.activated()
        }
    }
    // The shape is the island: one rectangle that changes size, rather than a
    // notch plus a panel. Its top edge stays in the bar and it grows downward.
    Rectangle {
        id: shape

        anchors.top: parent.top
        anchors.topMargin: Style.space(1)
        anchors.horizontalCenter: parent.horizontalCenter

        // Leaves the bar's own surface visible around it, so the shape reads
        // as cut into the bar rather than laid on top of it.
        implicitWidth: root.expanded ? root.expandedWidth : Math.max(cutout.implicitWidth + Style.space(3) * 2, Style.islandCutoutMinWidth)
        implicitHeight: root.cutoutHeight + (root.expanded ? panel.implicitHeight + session.implicitHeight + Style.space(3) * 2 : 0)
        width: implicitWidth
        height: implicitHeight

        // A capsule when small; squarer once it is a window, because a fully
        // rounded panel reads as a lozenge rather than something you can put
        // controls in.
        radius: root.expanded ? Style.radius * 2 : height / 2
        color: Theme.barBackground

        Behavior on width {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        // The cut-out strip is the handle at either size, and it toggles: it
        // opens the island when closed and closes it again when open.
        // Collapsed, cutoutHeight *is* the whole shape, so this is still the
        // capsule and its padding.
        //
        // Deliberately not the whole expanded shape. Everything below the strip
        // is what you opened the island to act on, and a click that dismissed a
        // notification and collapsed the island in one gesture would take the
        // surface away mid-task. Bar.qml still collapses on a click anywhere
        // outside.
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.cutoutHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        // The cut-out's own line, held at the top of the shape so it stays
        // where it was when the shape grows underneath it.
        RowLayout {
            id: cutout

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.cutoutHeight
            spacing: Style.space(1.5)

            // Context: the incoming notification, else this monitor's app and,
            // where focus is, its window title.
            RowLayout {
                visible: root.context !== "none"
                spacing: Style.space(1.5)
                Layout.alignment: Qt.AlignVCenter

                // Nerd Font U+F0F3 bell. Escapes rather than the glyphs
                // themselves -- a private-use codepoint is invisible in a diff
                // and has been lost twice in this tree already. It marks what
                // follows as a notification rather than an app name.
                Text {
                    visible: root.context === "notification"
                    text: "\uf0f3"
                    color: root.contextTint
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    id: contextLabel

                    text: root.contextText
                    color: root.contextTint
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    elide: Text.ElideRight
                    // A title is not a fact that has to survive whole the way
                    // an address is, so it elides rather than shrinking. The
                    // ceiling stops one long title pushing the bar's centre
                    // around.
                    Layout.maximumWidth: Style.islandCutoutText
                    Layout.alignment: Qt.AlignVCenter
                }

                // Muted, so the app reads first. Shares the one ceiling with
                // the name rather than having its own, and gives way first.
                Text {
                    visible: root.context === "window" && root.windowTitle !== ""
                    text: root.windowTitle
                    color: Theme.barTextMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    elide: Text.ElideRight
                    Layout.maximumWidth: Math.max(0, Style.islandCutoutText - contextLabel.implicitWidth - Style.space(1.5))
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
                visible: root.context !== "none" && root.hasStatus
                implicitWidth: Style.borderWidth
                implicitHeight: Math.round(root.cutoutHeight * 0.45)
                color: Theme.border
                Layout.leftMargin: Style.space(1)
                Layout.rightMargin: Style.space(1)
                Layout.alignment: Qt.AlignVCenter
            }

            // Status: badges, which never take turns.
            RowLayout {
                visible: root.hasStatus
                spacing: Style.space(2)
                Layout.alignment: Qt.AlignVCenter

                // Something is reading the camera, microphone or screen. Red
                // because being recorded without knowing is the one thing here
                // worth the loud colour; still, because it is a state rather
                // than something asking for a response.
                Rectangle {
                    visible: root.capturing
                    implicitWidth: Style.space(2)
                    implicitHeight: Style.space(2)
                    radius: width / 2
                    color: Theme.critical
                    Layout.alignment: Qt.AlignVCenter
                }

                // Media. The track itself is the expanded island's; here it is
                // only whether something is playing. U+F04B play, U+F04C pause.
                Text {
                    visible: root.hasMedia
                    text: root.hasMedia && root.player.isPlaying ? "\uf04b" : "\uf04c"
                    color: root.hasMedia && root.player.isPlaying ? Theme.barText : Theme.barTextMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    Layout.alignment: Qt.AlignVCenter
                }

                // The backlog badge. Nerd Font U+F0F3 bell, U+F1F6 bell slash --
                // shape answers the second question, the way the widget did.
                Text {
                    visible: root.hasBacklog
                    text: root.quiet ? "\uf1f6" : "\uf0f3"
                    color: root.backlogTint
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // The expanded half: what the cut-out could not say, and the controls.
        // Filled to the stated size rather than hugging its content, so the
        // window does not change shape as one track follows another.
        Item {
            id: expandedContent

            anchors.top: cutout.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.space(3)
            anchors.topMargin: 0

            opacity: root.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutCubic
                }
            }

            // Two columns: the player on the left, what is waiting on the
            // right. One panel holding everything the island has rather than a
            // choice between occupants -- a backlog must not hide the media
            // controls, because the cut-out shows one thing at a time only for
            // want of room, and expanding is where you came to find what else
            // there was.
            //
            // Side by side rather than stacked, which is also where the shape's
            // width comes from: see Style.islandWidth. The notification column
            // scrolls, and a player underneath a scrolling list is a set of
            // controls that moves whenever the list above it changes height. It
            // is also the column that takes any slack, so the player keeps its
            // size and the cards narrow instead.
            RowLayout {
                id: panel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Style.islandColumnGap

                // What is playing. Keeps its width whether or not anything is,
                // so the island does not change shape when a track starts.
                ColumnLayout {
                    spacing: Style.space(2)
                    Layout.preferredWidth: Style.islandPlayerColumn
                    Layout.alignment: Qt.AlignTop

                    Loader {
                        active: root.hasMedia
                        visible: active
                        sourceComponent: mediaPanel
                        Layout.fillWidth: true
                    }

                    // Said rather than left blank, for the reason the line
                    // opposite is: the column holds its width either way, so the
                    // space is there whatever happens and naming it beats a void.
                    Text {
                        visible: !root.hasMedia
                        text: "Nothing playing."
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // How you hear it, under what you are hearing.
                    Rectangle {
                        implicitHeight: Style.borderWidth
                        color: Theme.border
                        Layout.fillWidth: true
                    }

                    // The output, and beside it the way to the devices that
                    // could become one. The button stays when nothing is
                    // connected, which is when you need it.
                    RowLayout {
                        spacing: Style.space(1.5)
                        Layout.fillWidth: true

                        Rectangle {
                            implicitHeight: outputRow.implicitHeight + Style.space(2.5)
                            radius: Style.radius
                            color: outputHover.hovered ? Theme.surfaceHover : Theme.surface
                            border.width: Style.borderWidth
                            border.color: Theme.border
                            Layout.fillWidth: true

                            RowLayout {
                                id: outputRow

                                anchors.fill: parent
                                anchors.leftMargin: Style.space(2)
                                anchors.rightMargin: Style.space(2)
                                spacing: Style.space(2)

                                // U+F02CB headphones.
                                Text {
                                    text: "󰋋"
                                    color: Theme.barText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                }

                                Text {
                                    text: root.sink ? root.nodeName(root.sink) : "No output"
                                    color: root.sink ? Theme.barText : Theme.barTextMuted
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // U+F0140 chevron down, U+F0143 chevron up.
                                Text {
                                    text: root.outputsOpen ? "󰅃" : "󰅀"
                                    color: Theme.barTextMuted
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                }
                            }

                            HoverHandler {
                                id: outputHover
                            }

                            TapHandler {
                                onTapped: root.outputsOpen = !root.outputsOpen
                            }
                        }

                        // Opens Blueman, and puts the island away: the window
                        // that opens is where you are going next.
                        Rectangle {
                            implicitWidth: implicitHeight
                            implicitHeight: outputRow.implicitHeight + Style.space(2.5)
                            radius: Style.radius
                            color: bluetoothHover.hovered ? Theme.surfaceHover : Theme.surface
                            border.width: Style.borderWidth
                            border.color: Theme.border

                            // U+F00AF bluetooth.
                            Text {
                                anchors.centerIn: parent
                                text: "󰂯"
                                color: Theme.barText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSize
                            }

                            HoverHandler {
                                id: bluetoothHover
                            }

                            TapHandler {
                                onTapped: {
                                    root.expanded = false;
                                    Quickshell.execDetached(["blueman-manager"]);
                                }
                            }
                        }
                    }

                    // The outputs to choose from, the current one ticked.
                    ColumnLayout {
                        visible: root.outputsOpen
                        spacing: 0
                        Layout.fillWidth: true

                        Repeater {
                            model: root.sinks

                            delegate: Rectangle {
                                id: sinkRow

                                required property var modelData
                                readonly property bool current: sinkRow.modelData === root.sink

                                implicitHeight: sinkLabel.implicitHeight + Style.space(2)
                                radius: Style.radius
                                color: sinkHover.hovered ? Theme.surfaceHover : "transparent"
                                Layout.fillWidth: true

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Style.space(1.5)
                                    anchors.rightMargin: Style.space(1.5)
                                    spacing: Style.space(1.5)

                                    // U+F012C check.
                                    Text {
                                        text: "󰄬"
                                        opacity: sinkRow.current ? 1 : 0
                                        color: Theme.active
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontSizeSmall
                                    }

                                    Text {
                                        id: sinkLabel

                                        text: root.nodeName(sinkRow.modelData)
                                        color: sinkRow.current ? Theme.barText : Theme.barTextMuted
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontSizeSmall
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                HoverHandler {
                                    id: sinkHover
                                }

                                TapHandler {
                                    onTapped: {
                                        Pipewire.preferredDefaultAudioSink = sinkRow.modelData;
                                        root.outputsOpen = false;
                                    }
                                }
                            }
                        }
                    }

                    // Volume. Moving it unmutes, as raising a hardware knob would.
                    RowLayout {
                        visible: root.sink !== null
                        spacing: Style.space(2)
                        Layout.fillWidth: true

                        readonly property bool muted: root.sink && root.sink.audio ? root.sink.audio.muted : false

                        // U+F057E volume high, U+F0581 volume off.
                        IslandButton {
                            glyph: parent.muted ? "󰖁" : "󰕾"
                            color: parent.muted ? Theme.barTextMuted : Theme.barText
                            onActivated: root.sink.audio.muted = !root.sink.audio.muted
                        }

                        Controls.Slider {
                            id: volume

                            from: 0
                            to: 1
                            Layout.fillWidth: true

                            // Held off while dragging, so the slider is not
                            // pulled back by the value it is in the middle of
                            // writing.
                            Binding on value {
                                when: !volume.pressed
                                value: root.sink && root.sink.audio ? Math.min(root.sink.audio.volume, 1) : 0
                            }

                            onMoved: {
                                root.sink.audio.muted = false;
                                root.sink.audio.volume = volume.value;
                            }

                            background: Rectangle {
                                x: volume.leftPadding
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2
                                width: volume.availableWidth
                                height: Style.space(1)
                                radius: height / 2
                                color: Theme.surface

                                Rectangle {
                                    width: volume.visualPosition * parent.width
                                    height: parent.height
                                    radius: parent.radius
                                    color: volume.parent.muted ? Theme.barTextMuted : Theme.active
                                }
                            }

                            handle: Rectangle {
                                x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2
                                implicitWidth: Style.space(3)
                                implicitHeight: Style.space(3)
                                radius: width / 2
                                color: volume.parent.muted ? Theme.barTextMuted : Theme.active
                            }
                        }

                        Text {
                            text: parent.muted ? "off" : Math.round(volume.value * 100)
                            color: Theme.barTextMuted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: Style.space(7)
                        }
                    }

                    // The microphone: whether it is live, and the switch.
                    // Warning when muted, so talking into a muted call is
                    // caught at a glance.
                    RowLayout {
                        visible: root.source !== null
                        spacing: Style.space(2)
                        Layout.fillWidth: true

                        readonly property bool muted: root.source && root.source.audio ? root.source.audio.muted : false

                        // U+F036C microphone, U+F036D microphone off.
                        IslandButton {
                            glyph: parent.muted ? "󰍭" : "󰍬"
                            color: parent.muted ? Theme.warning : Theme.barText
                            onActivated: root.source.audio.muted = !root.source.audio.muted
                        }

                        Text {
                            text: root.nodeName(root.source)
                            color: Theme.barText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: parent.muted ? "muted" : "live"
                            color: parent.muted ? Theme.warning : Theme.barTextMuted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                        }
                    }

                    // Connected Bluetooth devices, each one click from let go.
                    // Gone entirely, rule and all, when nothing is connected.
                    Rectangle {
                        visible: root.bluetoothConnected.length > 0
                        implicitHeight: Style.borderWidth
                        color: Theme.border
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: root.bluetoothConnected

                        delegate: Rectangle {
                            id: deviceRow

                            required property var modelData

                            implicitHeight: deviceLabel.implicitHeight + Style.space(2.5)
                            radius: Style.radius
                            color: Theme.surface
                            Layout.fillWidth: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Style.space(2)
                                anchors.rightMargin: Style.space(1.5)
                                spacing: Style.space(2)

                                // U+F00AF bluetooth.
                                Text {
                                    text: "󰂯"
                                    color: Theme.active
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                }

                                Text {
                                    id: deviceLabel

                                    text: deviceRow.modelData.name
                                    color: Theme.barText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: deviceRow.modelData.batteryAvailable
                                    text: Math.round(deviceRow.modelData.battery * 100) + "%"
                                    color: Theme.barTextMuted
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                }

                                // U+F0156 close.
                                IslandButton {
                                    glyph: "󰅖"
                                    color: Theme.barTextMuted
                                    font.pixelSize: Style.fontSizeSmall
                                    onActivated: deviceRow.modelData.disconnect()
                                }
                            }
                        }
                    }
                }
                // What is waiting, and the two controls that act on all of it.
                // This column takes the slack, so a display too narrow for the
                // stated width narrows the cards rather than the player.
                ColumnLayout {
                    spacing: Style.space(2)
                    Layout.fillWidth: true
                    Layout.preferredWidth: Style.islandNotificationColumn
                    Layout.alignment: Qt.AlignTop

                    // The stack. Newest first, the same card the popup was --
                    // "the same card as a popup and in the history" is the
                    // notification's own rule, and this is a third place it is
                    // read rather than a third way of drawing it.
                    ListView {
                        id: list

                        model: root.stacked
                        spacing: Style.space(2)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: root.stacked.length > 0

                        // Measure only the first four cards independently of the
                        // virtualized delegates, so scrolling cannot resize the panel.
                        implicitHeight: Math.min(preview.implicitHeight, Style.islandMaxStack)

                        Column {
                            id: preview

                            visible: false
                            width: list.width - Style.space(3)
                            spacing: list.spacing

                            Repeater {
                                model: root.stacked.slice(0, 4)

                                delegate: NotificationCard {
                                    required property var modelData

                                    width: preview.width
                                    record: modelData
                                    bodyLines: 4
                                }
                            }
                        }

                        Controls.ScrollBar.vertical: Controls.ScrollBar {
                            id: scrollBar

                            policy: Controls.ScrollBar.AsNeeded
                            visible: list.contentHeight > list.height
                            contentItem: Rectangle {
                                implicitWidth: Style.space(1)
                                radius: width / 2
                                color: scrollBar.pressed ? Theme.active : Theme.barTextMuted
                            }
                            background: Item {}
                        }

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight

                        delegate: NotificationCard {
                            id: card

                            required property var modelData

                            width: list.width - Style.space(3)
                            record: card.modelData
                            bodyLines: 4

                            onCloseClicked: NotificationCenter.dismiss(card.modelData.id)
                            onActionClicked: identifier => NotificationCenter.activate(card.modelData.id, identifier)
                            onActivated: NotificationCenter.activate(card.modelData.id, "")
                        }
                    }

                    // What the history panel carried, because the island is that
                    // panel now: the switch for whether you will be told, and the
                    // way to be done with all of it at once.
                    RowLayout {
                        spacing: Style.space(2)
                        Layout.fillWidth: true

                        IslandChip {
                            label: (root.quiet ? "\uf1f6" : "\uf0f3") + "  Do not disturb"
                            on: root.quiet
                            onActivated: NotificationCenter.setDoNotDisturb(!root.quiet)
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        IslandChip {
                            visible: NotificationCenter.history.length > 0
                            label: "Clear all"
                            onActivated: NotificationCenter.clearAll()
                        }
                    }

                    // Said rather than left as an empty panel: do-not-disturb can
                    // hold the island open with nothing in it, and that is the one
                    // state you must not forget you are in.
                    Text {
                        visible: NotificationCenter.history.length === 0
                        text: root.quiet ? "Nothing waiting. Do not disturb is on." : "Nothing waiting."
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // The session: the power menu's five actions, across the whole
            // island under both columns, since they act on everything above.
            // The same actions and the same SessionControl as the menu, which
            // stays where Ctrl+Alt+Delete reaches it.
            ColumnLayout {
                id: session

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: panel.bottom
                anchors.topMargin: Style.space(3)
                spacing: Style.space(2)

                Rectangle {
                    implicitHeight: Style.borderWidth
                    color: Theme.border
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Style.space(1.5)
                    Layout.fillWidth: true

                    Repeater {
                        model: SessionControl.actions

                        delegate: Rectangle {
                            id: action

                            required property var modelData
                            readonly property bool armed: root.armed === action.modelData.id

                            implicitHeight: actionColumn.implicitHeight + Style.space(4)
                            radius: Style.radius
                            color: action.armed ? Theme.warning : (actionHover.hovered ? Theme.surfaceHover : "transparent")
                            Layout.fillWidth: true

                            ColumnLayout {
                                id: actionColumn

                                anchors.centerIn: parent
                                spacing: Style.space(1)

                                Text {
                                    text: action.modelData.icon
                                    color: action.armed ? Theme.barBackground : Theme.barText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSize + 2
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: action.modelData.label
                                    color: action.armed ? Theme.barBackground : Theme.barText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                    font.bold: action.armed
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover
                            }

                            TapHandler {
                                onTapped: root.act(action.modelData)
                            }
                        }
                    }
                }

                // The confirmation, where the power menu puts it. Holds its
                // line when empty, so arming does not change the island's size.
                Text {
                    readonly property var armedAction: {
                        for (var i = 0; i < SessionControl.actions.length; i++) {
                            if (SessionControl.actions[i].id === root.armed)
                                return SessionControl.actions[i];
                        }
                        return null;
                    }

                    text: armedAction ? "Click again to " + armedAction.label.toLowerCase() + " · Esc to cancel" : ""
                    color: Theme.warning
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }
    }

    Component {
        id: mediaPanel

        ColumnLayout {
            spacing: Style.space(2)

            RowLayout {
                spacing: Style.space(2.5)
                Layout.fillWidth: true

                // The art if the player offers one. Nothing is drawn when it
                // does not, rather than a placeholder standing in for an
                // answer nobody asked for.
                Rectangle {
                    visible: art.status === Image.Ready
                    implicitWidth: Style.islandArt
                    implicitHeight: Style.islandArt
                    radius: Style.radius
                    color: Theme.surface
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.hasMedia && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    spacing: Style.space(0.5)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.hasMedia ? root.player.trackArtist : ""
                        visible: text !== ""
                        color: Theme.barText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.hasMedia ? root.player.trackAlbum : ""
                        visible: text !== ""
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.hasMedia ? root.player.identity : ""
                        visible: text !== ""
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                spacing: Style.space(5)
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true

                IslandButton {
                    glyph: "\uf048"
                    enabled: root.hasMedia && root.player.canGoPrevious
                    onActivated: root.player.previous()
                }

                IslandButton {
                    glyph: root.hasMedia && root.player.isPlaying ? "\uf04c" : "\uf04b"
                    enabled: root.hasMedia && root.player.canTogglePlaying
                    onActivated: root.player.togglePlaying()
                }

                IslandButton {
                    glyph: "\uf051"
                    enabled: root.hasMedia && root.player.canGoNext
                    onActivated: root.player.next()
                }
            }
        }
    }

}
