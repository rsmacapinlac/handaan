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
// Colour carries severity, on a three-level ladder ranked by consequence:
// packages behind (red) over a handaan not pulled (peach) over migrations not
// applied (muted). The pulse rides the top of it, which is the battery's
// discipline -- it pulses at critical, not whenever it is drawn.
//
// The reservation stands and is worth keeping in front of whoever reads this
// next. docs/quickshell-widgets.md rations motion to one thing on the bar and
// requires it to stop when its condition clears; Workspaces spends it on an
// urgent window and Battery on a flat one, both rare and both self-clearing.
// Package updates are neither. They are available most days and never clear on
// their own, so the top of this ladder is where the widget spends most of its
// visible life, and the pulse with it. That is the known cost of ranking by
// consequence rather than by rarity, and it was chosen deliberately: an
// unpatched system is the more serious fact, even though the rarer one would
// make the better signal. If the channel starts reading as noise, this is the
// pulse to drop first.
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

    // Severity by the kind of thing waiting, not the amount -- the same shape
    // as the battery's ladder, where 40% and 10% differ in kind (plan to act,
    // act now) rather than in magnitude. Ranked by consequence: an unpatched
    // system outranks a handaan this checkout has not pulled, which outranks
    // bookkeeping the machine has not applied.
    //
    //   1  migrations   handaan's own repairs, not yet run
    //   2  commits      a newer handaan exists
    //   3  packages     the system itself is behind
    //
    // A source whose check could not run reports -1 and so fails every test
    // here, which is the decided behaviour: an unknown counts as nothing
    // waiting from that source. It still says so in the tooltip -- treating a
    // failed check as zero for ranking is not the same as pretending it
    // succeeded.
    //
    // Highest wins. A machine with a pending migration and forty packages is
    // ranked by the packages, so the rarer problem is reported by the tooltip
    // rather than the colour.
    readonly property int level: {
        if (Maintenance.arch > 0)
            return 3;
        if (Maintenance.handaanCommits > 0)
            return 2;
        if (Maintenance.handaanMigrations > 0)
            return 1;
        return 0;
    }

    readonly property color tint: {
        if (root.level >= 3)
            return Theme.critical;
        if (root.level === 2)
            return Theme.warning;
        return Theme.barTextMuted;
    }

    // The pulse's amplitude, shared with the glyph's resting size below so the
    // two cannot drift apart. Matches the workspace and battery pulses.
    readonly property real pulseScale: 1.12

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
        // Drawn at what the pulse used to peak at, so the glyph reads at that
        // size all the time rather than only for a moment every 1.2s. The
        // multiplier is the pulse's own amplitude rather than a second number
        // to keep in sync: change one and the other follows.
        font.pixelSize: Math.round(Style.fontSize * root.pulseScale)

        // Same cycle and amplitude as the workspace and battery pulses, so the
        // bar has one vocabulary for "look at this" rather than three.
        //
        // Bound to the top of the ladder rather than to the widget existing,
        // which is the battery's discipline: it pulses at critical, not
        // whenever it is drawn. The reservation recorded at the top of the file
        // still stands, and is sharper here than for the battery -- package
        // updates are available most days and never clear on their own, so the
        // top level is where this widget spends most of its visible life.
        SequentialAnimation on scale {
            running: root.level >= 3
            loops: Animation.Infinite
            alwaysRunToEnd: true

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
