// Pending updates.
//
// One question, per docs/quickshell-widgets.md:
//   1. Is there anything for me to update?
//
// Two sources answer it -- package updates, and a handaan that has moved on or
// has migrations to apply -- but they are one question. Both end in the same
// place: open a terminal and deal with it. Which of the two is precision, and
// precision is the hover layer's job.
//
// Presence is the entire glance encoding. The widget is absent when there is
// nothing to update and present when there is, which the doc's
// two-strong-states rule makes the strongest signal available: the states are
// "a widget" and "no widget at all", and nothing else on the bar has to be
// read to tell them apart. BarWidget.active drops the widget and its spacing
// from the row, so an up-to-date machine has no update chrome on it whatsoever.
//
// This widget counted apps-to-install as a third source at first, because the
// question it was asked was "do I have apps to install, or updates". That was
// wrong, and wrong in a way worth recording: ~/.config/handaan/apps offers
// everything its owner might want on any machine, so on a machine that is not
// all of them at once the count never reaches zero. Presence was therefore
// permanent, and a signal that is always on carries nothing -- the same
// failure as an animation that never stops, one layer up. It also failed the
// doc's first test outright: "you have not installed Citrix" changes nothing
// about what happens next. The app list is a catalogue, not a chore, and it
// belongs in `handaan apps` where it is chosen from deliberately.
//
// Putting apps in the tooltip instead would have been worse, not better. Hover
// may sharpen an answer the widget already gave; it may not introduce a
// question the widget does not claim to answer, and "what could I install" is
// a different question from "what needs updating".
//
// There is no count on the glance layer. A numeral beside the icon would be a
// second thing to parse that changes nothing: two updates and forty both mean
// "go and deal with it", and neither the decision nor its urgency differs. The
// figures live on hover, where the battery widget puts its percentage and for
// the same reason.
//
// Nothing moves, and this was asked about directly. Motion means "this needs a
// response" and is rationed to one thing on the whole bar; Workspaces spends
// it on an urgent window and Battery on a flat one, both conditions that clear
// when handled. Available updates do not clear -- on Arch they are true most
// days -- so a pulse bound to them is a permanent animation, which the doc says
// trains the eye to discard the one channel that has to survive peripheral
// vision. An update can wait for the end of what you are doing; that is the
// definition of the thing that must not animate.
//
// Click re-checks, and that is the only interaction. See the MouseArea below
// for why it is that rather than a shortcut to a terminal.
//
// A check that cannot run is not the same as nothing to do. Maintenance keeps
// those apart (-1 against 0) and this widget refuses to appear on the strength
// of an unknown: a missing checkupdates or a fetch that failed before the
// network was up would otherwise light the bar on every boot. When the widget
// is up for other reasons the tooltip says which check is blind, because the
// doc's rule is to say why a value is missing rather than go quiet about it.

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "updates"

    // Shown only when a check actually found something. `polled` gates the
    // first seconds after login, where every count is still -1 and `updates`
    // would read 0 anyway -- but saying so explicitly keeps the widget from
    // depending on that coincidence.
    active: Maintenance.polled && Maintenance.updates > 0

    // The glyph's own width, with nothing added. Battery and Clock are both a
    // bare row width, so padding here made this the only widget in the section
    // wider than its content -- measured at 44px between this and the battery
    // against 20px between the battery and the clock, and half that excess was
    // this. The click target keeps the padding, as a negative margin on the
    // MouseArea below, because a hit area is not a layout size.
    implicitWidth: icon.implicitWidth

    // Peach rather than red. This is "there is work waiting", not "something
    // is wrong": red is the bar's critical level and belongs to a flat battery
    // and an urgent window, and spending it here would flatten the ladder that
    // makes those legible.
    readonly property color tint: Theme.warning

    // The parts of the answer, in the order they are worth acting on. Built as
    // a list so the tooltip never prints a source with nothing waiting -- a
    // line reading "0 packages" is noise on a layer that exists to be precise.
    readonly property var parts: {
        var out = [];
        if (Maintenance.arch > 0)
            out.push(Maintenance.arch + (Maintenance.arch === 1 ? " package update" : " package updates"));
        if (Maintenance.handaanCommits > 0)
            out.push(Maintenance.handaanCommits + (Maintenance.handaanCommits === 1 ? " handaan commit" : " handaan commits"));
        if (Maintenance.handaanMigrations > 0)
            out.push(Maintenance.handaanMigrations + (Maintenance.handaanMigrations === 1 ? " migration" : " migrations"));
        return out;
    }

    readonly property string summary: {
        const n = Maintenance.updates;
        return n + (n === 1 ? " update waiting" : " updates waiting");
    }

    // Named rather than listed: which check is blind is the useful half, and a
    // machine with no checkupdates would otherwise show a tooltip that quietly
    // undercounts with no sign of it.
    readonly property string blind: {
        var out = [];
        if (!Maintenance.known(Maintenance.arch))
            out.push("packages");
        if (!Maintenance.known(Maintenance.handaanCommits))
            out.push("handaan");
        if (out.length === 0)
            return "";
        return "Could not check: " + out.join(", ");
    }

    // Detail on request, and only ever the same question at higher
    // resolution: the glance layer said updates are waiting, this says how
    // many and of what. Nothing here is required to read the widget.
    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.summary
        detail: root.parts.join("\n") + (root.blind !== "" ? "\n" + root.blind : "")
    }

    // Click re-checks. It is the obvious action for this widget's question:
    // the counts are up to half an hour old, so the moment the answer matters
    // most is just after you have acted on it and want to know it took. A poll
    // only asks the question again, so an accidental click costs a database
    // sync and changes nothing -- which is what the doc requires of anything
    // reachable by a stray press.
    //
    // Deliberately not "open a terminal and update". There is no single action
    // behind these counts -- packages want `handaan update`, a migration wants
    // `handaan migrate` -- and the doc prefers the terminal-first tool that
    // already does the job over a second interface built into the bar.
    // Reaches past the widget's own bounds so a 13px glyph is not a 13px
    // target. It grows into the gap either side, which is free: the widgets
    // it borders have no click handlers of their own to steal from.
    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -Style.widgetPadding
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: Maintenance.refresh()
    }

    Text {
        id: icon
        anchors.centerIn: parent
        // Nerd Font U+F019, "arrow down into tray": the shape the desktop
        // already uses for "there is something to fetch and apply".
        //
        // Written as an escape rather than the literal glyph. A private-use
        // codepoint is invisible in most diffs and editors, and this one was
        // silently lost once already when the file was rewritten -- the widget
        // went on reporting itself active while drawing an empty Text, so it
        // had zero width and never appeared, with nothing in any log to say
        // why. The escape is greppable, survives a rewrite, and names the
        // codepoint it means.
        text: "\uf019"
        color: root.tint
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize

        // Same cycle and amplitude as the workspace and battery pulses, so the
        // bar has one vocabulary for "look at this" rather than three. Bound to
        // the condition, not to the widget's existence, so it stops the moment
        // the counts reach zero -- though for this widget those are nearly the
        // same thing, which is the reservation recorded at the top of the file.
        SequentialAnimation on scale {
            running: root.active
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

        // A transition, not motion: the widget appears when a poll lands, and
        // fading it in over a beat makes the arrival legible as a change
        // rather than a glyph that was always there and you had missed.
        // Bounded and over before you look, which is what the doc separates
        // from the sustained kind.
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }
    }
}
