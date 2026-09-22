// Workspace indicators.
//
// Two questions, per docs/quickshell-widgets.md:
//   1. Which workspace is this screen on?
//   2. Which workspace wants attention?
//
// The widget shows exactly those two things and nothing else. Each is encoded
// three ways at once -- size, shape, and colour -- so it resolves in peripheral
// vision without being looked at. Every other workspace is an identical neutral
// dot: not a state, just scaffolding, so the pills have somewhere to sit and
// position stays readable.
//
// Every workspace is labelled, including the idle ones. The numeral is
// identity, not a state: it says *which* workspace, never how it is doing. A
// bare dot only implies its number when the row happens to be contiguous, and
// with workspaces 1, 3 and 7 alive it is unreadable -- you would be clicking
// blind. Identity is cheap here because the pill already carries both answers
// through size, shape and fill, so a muted numeral cannot be mistaken for one.
//
// The first answer carries one refinement: whether this screen also holds
// focus. With two monitors, each is displaying a workspace, and drawing both as
// the same filled pill left no way to tell which one the keyboard was on. So
// the displayed workspace keeps the wide pill on every screen, and only the
// focused monitor's pill is filled; the other is an outline in the same
// colour. That is a third state against the two-strong-states rule in
// docs/quickshell-widgets.md, and it is allowed because it is not a new
// question: it is the same answer, drawn with or without fill. Width still says
// "this screen is on it", so nothing reflows when focus crosses monitors, and
// exactly one filled accent pill exists across the whole session.
//
// What is deliberately absent is whether a workspace holds windows, which
// answers neither question: you are not on it, and it is not asking for you.
//
// All of that describes the top bar, where the row can grow sideways for as
// long as it likes. A side bar cannot: five slots divide a fixed width budget
// (Style.barSideSize), which leaves each one around eighteen pixels. At that
// size width has nothing left to say -- the strong pill and the idle dot would
// differ by a few pixels, which is no longer a channel that survives
// peripheral vision -- so every slot there is drawn the same width, and the
// two answers are carried by fill, outline and colour alone. That is a real
// loss against the reasoning above, accepted because the alternative is a
// bar wide enough to matter: five pills at their top-bar size need 184px of
// screen where the whole side bar is 120.
//
// Holding the width still has a second benefit on a bar that narrow: nothing
// reflows as focus moves. The bar's width is taken from this widget, so a slot
// that grew and shrank would pull the whole bar with it.
//
// An earlier version separated states by colour alone -- accent fill for
// focused, opacity 0.45 vs 1.0 for empty vs occupied, every numeral the same
// weight. The empty and occupied numerals composited about 21/255 apart, so
// the row read as undifferentiated digits and neither answer stood out. The
// lesson was that colour alone is too weak a channel, not that numerals are.
//
// Only workspaces that exist are drawn. Hyprland destroys a workspace when its
// last window closes, so "exists" already means "has windows, or is the one you
// are on" -- the widget gets that for free as presence, without spending any
// contrast to encode it.
//
// A fixed 1-5 was drawn here at first, justified as keeping the bar from
// reflowing. That was backwards: four dots for workspaces that do not exist
// answer neither question, and the row is a truer picture of the session when
// it is allowed to grow and shrink.
//
// And only the workspaces on *this* bar's monitor are drawn. The bar is
// instantiated once per screen, and drawing the session's whole list on each
// one made both rows identical -- the same digits in the same order, differing
// only in which pill was lit. A workspace living on the other monitor answers
// neither question about this one: you are not on it, and you cannot be sent
// to it without leaving the screen you are looking at.
//
// The cost is deliberate and worth writing down: an urgent workspace on the
// other monitor no longer appears here. That narrows the second question from
// "which workspace wants attention" to "which workspace *on this screen* wants
// attention". It holds because the pill still pulses on the monitor that owns
// it, and that monitor is by definition one you can see -- and because closing
// the lid does not create a blind spot, since disabling the panel migrates its
// workspaces onto the remaining output, where this row picks them up.
//
// Workspaces are not pinned to monitors anywhere in conf/; Hyprland binds a new
// one to whichever monitor was focused when it was created. So each row is
// emergent and will drift with use, and the numerals are not a positional index
// into the row -- another reason every slot stays labelled.
//
// Note that the keybinds do not agree with this. `super+N` in conf/binds.lua is
// session-global: pressed on the laptop it focuses workspace N wherever it
// lives, which may change the *other* bar's row and leave this one untouched.
// That is a known and accepted mismatch, not an oversight.

import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "workspaces"

    // Geometry of the two shapes. The strong pill is deliberately several times
    // the dot's area: size is the channel that survives peripheral vision.
    readonly property int pillWidth: Style.space(8)
    readonly property int pillHeight: Style.space(5.5)
    // Idle slots are narrower but the same height, so the numerals sit on one
    // baseline and only the pill's width marks it out.
    readonly property int idleWidth: Style.space(5)
    readonly property int slotStrong: pillWidth
    readonly property int slotWeak: idleWidth
    // The unfocused monitor's outline. Twice the chrome border, because a
    // hairline around a filled-sized pill reads as idle at a glance.
    readonly property int outlineWidth: Style.borderWidth * 2

    // Which workspace *this screen* is displaying.
    //
    // Hyprland.focusedWorkspace is global -- one value for the whole session --
    // so reading it here highlighted the same pill on every monitor's bar
    // regardless of what that monitor was actually showing. With the laptop on
    // 1 and the external on 3, both bars lit 1. The widget's first question is
    // "which workspace is *this screen* on", so the answer has to come from
    // this instance's own monitor.
    //
    // Connector names are not written down here on purpose. conf/monitors.lua
    // matches the external by `desc:` precisely because the port floats -- the
    // same panel has come up as DP-4 and DP-6 -- so the widget compares monitor
    // objects and never a name.
    readonly property var monitor: root.screen !== null ? Hyprland.monitorFor(root.screen) : null
    readonly property int activeId: {
        if (root.monitor === null || root.monitor.activeWorkspace === null)
            return -1;
        return root.monitor.activeWorkspace.id;
    }
    // Whether this screen holds session focus. Read off this instance's own
    // monitor, so exactly one bar answers true at a time.
    readonly property bool monitorFocused: root.monitor !== null && root.monitor.focused

    // Positive ids only: Hyprland numbers special workspaces (scratchpads)
    // negatively, and those are summoned by name rather than picked out of a
    // row, so they answer neither question.
    readonly property var workspaceIds: {
        var ids = [];
        var mon = root.monitor;
        if (mon === null)
            return ids;

        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            var ws = values[i];
            if (ws.id <= 0)
                continue;
            // Reading ws.monitor is what subscribes this binding to it, so
            // moving a workspace between outputs -- by dispatcher, or by the
            // migration that disabling the panel forces -- re-filters both
            // rows on its own. Comparing objects rather than names keeps this
            // honest when a connector is renumbered across a replug.
            //
            // The activeId escape hatch covers the moment before the links
            // populate: this monitor's own active workspace is on this monitor
            // by definition, so it is drawn even if ws.monitor is still null,
            // and the row is never briefly empty at startup.
            if (ws.monitor !== mon && ws.id !== root.activeId)
                continue;
            if (ids.indexOf(ws.id) === -1)
                ids.push(ws.id);
        }
        ids.sort(function (a, b) {
            return a - b;
        });
        return ids;
    }

    function workspaceById(id) {
        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i];
        }
        return null;
    }

    // This Hyprland is configured in Lua, and its dispatcher parses Lua too:
    // `dispatch workspace 3` fails with a Lua syntax error. The call has to be
    // written as the Lua expression the compositor evaluates. Verified against
    // Hyprland 0.56.2 -- see docs/hyprland-startup.md.
    function focusWorkspace(id) {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })');
    }

    // One row on a top bar, a grid five wide on a side one. Five is what the
    // bar is sized around: wider and it starts eating the screen, and
    // a row of five is still short enough to take in at a glance.
    readonly property int columnsAcross: 5
    readonly property int acrossGap: Style.space(1)
    // The slot size five-across implies, taken from the side bar's width
    // budget rather than from the top bar's pill: at the top the row grows
    // sideways for free, while here five have to fit a fixed bar.
    readonly property int slotAcross: Math.floor((Style.barSideSize - Style.barSidePadding * 2 - root.acrossGap * (root.columnsAcross - 1)) / root.columnsAcross)
    readonly property int acrossWidth: root.slotAcross * root.columnsAcross + root.acrossGap * (root.columnsAcross - 1)

    // The side bar holds room for all five whether or not five exist. The row
    // is emergent -- Hyprland destroys a workspace with its last window -- so
    // a widget sized to the live count would change the bar's width, and with
    // it every window's geometry, each time one came or went.
    implicitWidth: root.vertical ? root.acrossWidth : row.implicitWidth
    implicitHeight: root.vertical ? row.implicitHeight : root.barSize

    // A positioner rather than a layout. A GridLayout shares its width out
    // between the columns it is using, so a row holding two workspaces spaced
    // them across the whole bar and a full row of five packed them tight --
    // the gap moved with the count. Grid gives every child its own size and
    // one spacing, so five across and two across sit at the same pitch.
    Grid {
        id: row
        anchors.left: root.vertical ? parent.left : undefined
        anchors.fill: root.vertical ? undefined : parent
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        columns: root.vertical ? root.columnsAcross : Math.max(1, root.workspaceIds.length)
        spacing: root.vertical ? root.acrossGap : Style.space(1.5)

        Repeater {
            model: root.workspaceIds

            delegate: Item {
                id: slot

                required property int modelData

                readonly property var workspace: root.workspaceById(modelData)
                // On screen here, whether or not this monitor has focus. Not
                // named `visible`: that is Item's own property.
                readonly property bool displayed: root.activeId === modelData
                readonly property bool focused: displayed && root.monitorFocused
                // Hyprland clears urgency when you arrive, so the two strong
                // states rarely coincide. If they do, focused wins: you are
                // already looking at it, which is what urgency was asking for.
                // Displayed without focus does not win: the keyboard is
                // elsewhere, so the request has not been answered yet.
                readonly property bool urgent: workspace !== null && workspace.urgent && !focused
                readonly property bool strong: focused || urgent
                readonly property bool wide: strong || displayed

                // Animated so the row grows and shrinks as focus moves rather
                // than snapping, which makes the change legible as movement.
                property real slotWidth: wide ? root.slotStrong : root.slotWeak

                Behavior on slotWidth {
                    NumberAnimation {
                        duration: Style.animationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                // On a side bar the slot keeps one width whatever it is
                // doing, so neither the pitch of the row nor the width of the
                // bar -- which is taken from this widget -- moves with focus.
                width: root.vertical ? root.slotAcross : slot.slotWidth
                height: root.vertical ? root.pillHeight : root.barSize

                Rectangle {
                    id: shape

                    anchors.centerIn: parent
                    // One width for every slot on a side bar. See the note on
                    // the grid above: the shapes are too small there for width
                    // to say anything, and a row that reflowed as focus moved
                    // would be the only motion in a bar whose whole point is
                    // to sit still.
                    width: root.vertical ? root.slotAcross : (slot.wide ? root.pillWidth : root.idleWidth)
                    height: root.pillHeight
                    radius: height / 2

                    // Displayed on the unfocused monitor: the pill's outline
                    // without its fill. Suppressed when urgent, whose fill is
                    // already the stronger signal.
                    border.width: slot.displayed && !slot.strong ? root.outlineWidth : 0
                    border.color: Theme.active

                    // Fill is reserved for the two answers. An idle or merely
                    // displayed slot has none; hover gives it a quiet surface
                    // so the click target is discoverable, which is an
                    // affordance, not a state.
                    color: {
                        if (slot.focused)
                            return Theme.active;
                        if (slot.urgent)
                            return Theme.urgent;
                        return mouse.containsMouse ? Theme.surfaceHover : "transparent";
                    }

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
                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                    // A slow pulse on urgency only. Motion is the one channel
                    // that reaches you when you are not looking at the bar,
                    // which is exactly the case urgency has to survive.
                    SequentialAnimation on scale {
                        running: slot.urgent
                        loops: Animation.Infinite
                        alwaysRunToEnd: true

                        NumberAnimation {
                            to: 1.12
                            duration: 620
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 620
                            easing.type: Easing.InOutSine
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: String(slot.modelData)
                        // Dark on the filled pill; accent inside the outline, so
                        // it matches its border; muted when idle, so identity is
                        // readable without competing with the answers.
                        color: {
                            if (slot.strong)
                                return Theme.barBackground;
                            if (slot.displayed)
                                return Theme.active;
                            return mouse.containsMouse ? Theme.barText : Theme.barTextMuted;
                        }
                        font.family: Style.fontFamily
                        // Larger on a side bar, where the numeral is most of
                        // what is left to read: the pill lost its width cue to
                        // the bar's budget. Capped by that same budget --
                        // a two-digit workspace has to sit inside an 18px
                        // slot, which the body size just manages.
                        font.pixelSize: root.vertical ? Style.fontSize : Style.fontSizeSmall
                        font.bold: slot.strong

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                            }
                        }
                    }
                }

                // The hit area is the whole slot, not the dot: an 8px target is
                // not clickable in practice.
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(slot.modelData)
                }
            }
        }
    }
}
