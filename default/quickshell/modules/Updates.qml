// Pending updates.
//
// One question, per docs/bar.md:
//   1. Is there anything for me to update?
//
// Two sources answer it -- package updates, and a handaan that has moved on or
// has migrations to apply -- but they are one question. Both end in the same
// place: `handaan update`, which pulls the checkout, upgrades packages and runs
// migrations in one pass. Which of the two is precision, and precision is the
// hover layer's job.
//
// Security fixes are not a third source. They are a subset of the first: the
// pending package updates that carry a published fix, counted separately by
// handaan-pending because nothing local distinguishes them. They do not change
// what you do -- it is the same command -- they change when you do it, which is
// why they rank above everything else and take the pulse.
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
// The count is on the glance layer, beside the glyph, with the name of the
// rung driving it underneath. It was not always: the widget shipped as a bare
// icon on the argument that two updates and forty both mean "go and deal with
// it", so a numeral was a second thing to parse that changed nothing.
//
// That argument was sound while every rung meant the same act. It stopped
// being sound when the security rung arrived, because "71 packages" and "71
// packages, 1 of them a security fix" are not the same fact and do not prompt
// the same timing -- and a bare icon can only carry that in colour, which is
// the one channel already spent on the ladder. The card's text column was
// reserved and empty; this is what it was reserved for.
//
// Colour carries one distinction, not a gradient: security fixes waiting
// (red, pulsing) against anything else waiting (muted). The ladder underneath
// still ranks four rungs -- security over packages over commits over
// migrations -- but only the top one is drawn differently, because only it
// changes what you do. The rest clear with one `handaan update` and are told
// apart in the tooltip.
//
// That top rung is what makes the pulse legitimate here, and it has not always
// been. docs/bar.md rations motion to one thing on the bar and
// requires it to stop when its condition clears; Workspaces spends it on an
// urgent window and Battery on a flat one, both rare and both self-clearing.
// The pulse used to ride "packages behind", which is neither: on Arch that is
// true most days and never clears on its own, so the widget spent most of its
// visible life animating -- the shape the doc calls decoration, and a standing
// reservation recorded here for as long as it lasted.
//
// Binding it to security fixes resolves exactly that. A published fix you have
// not installed is rare, and it clears when you install it, which is the
// property the rule asks for and the one the old top rung never had. This is
// no longer the pulse to drop first if the channel starts reading as noise.
//
// It is not free. The rung depends on arch-audit being installed and the Arch
// Security Team's tracker being reachable, so it is the one rung that can go
// blind -- and a blind rung reports nothing waiting. See bin/handaan-pending
// for how the count is derived and the two things it cannot see (the AUR, and
// versioned package names like electron42 against the tracker's electron).
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

    // A card, so on a side bar this is the bar's full width and the glyph
    // centres in the rail with every other card's. On a top bar the card gives
    // the empty text column back and this is the glyph's own width again, with
    // nothing added: padding here once made this the only widget in the
    // section wider than its content. The click target keeps the padding, as a
    // negative margin on the MouseArea below, because a hit area is not a
    // layout size.
    //
    // Two lines beside the glyph now, so on a side bar this is the full card
    // width rather than the glyph's own. See the header for why the text
    // column stopped being empty.
    implicitWidth: card.implicitWidth

    // Severity by the kind of thing waiting, not the amount -- the same shape
    // as the battery's ladder, where 40% and 10% differ in kind (plan to act,
    // act now) rather than in magnitude. Ranked by consequence: an unpatched
    // system outranks a handaan this checkout has not pulled, which outranks
    // bookkeeping the machine has not applied.
    //
    //   1  migrations   handaan's own repairs, not yet run
    //   2  commits      a newer handaan exists
    //   3  packages     the system itself is behind
    //   4  security     some of those packages carry a published fix
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
        if (Maintenance.archSecurity > 0)
            return 4;
        if (Maintenance.arch > 0)
            return 3;
        if (Maintenance.handaanCommits > 0)
            return 2;
        if (Maintenance.handaanMigrations > 0)
            return 1;
        return 0;
    }

    // Four rungs, two colours. Rungs 1 to 3 render identically and that is the
    // point rather than an economy: `handaan update` pulls the checkout,
    // upgrades packages and runs migrations in one pass, so all three clear
    // with the same command and differ only in what is waiting -- which is the
    // tooltip's job, not the glyph's. Only the security rung changes what you
    // do, by changing when you do it, so only it gets a colour of its own.
    //
    // That is the doc's "two states may be strong, everything else recedes"
    // applied honestly. An earlier version spent peach on rung 3, which made
    // the ladder legible at the cost of ranking three states no one acts on
    // differently -- and peach is Network's and Battery's warning, where it
    // means something a user can respond to.
    //
    // The rungs stay four even though two would draw the same, because the
    // ranking is what picks the number on the card and the order in the
    // tooltip.
    readonly property color tint: root.level >= 4 ? Theme.critical : Theme.barTextMuted

    // The pulse's amplitude, shared with the glyph's resting size below so the
    // two cannot drift apart. Matches the workspace and battery pulses.
    readonly property real pulseScale: 1.12

    // What the card counts changes with the rung, because what it is telling
    // you changes with it. Below the security rung it is the roll-up --
    // packages, commits and migrations together -- since those clear with one
    // command and splitting them here would be three numbers for one act. On
    // the security rung it is the security count alone: "3" beside a red
    // pulsing glyph is the figure that decides whether you update now, and the
    // roll-up is a larger number that would bury it. The tooltip holds both in
    // every state, which is what makes narrowing the card safe.
    readonly property string countText: root.level >= 4 ? Maintenance.archSecurity : Maintenance.updates

    // The rung in words, which is not redundant with the glyph's colour: the
    // doc requires a state to be readable without the channel that escalates
    // it, so "security" is what says so on a screen the pointer is nowhere
    // near, or to anyone who does not separate the two tints by eye.
    //
    // Abbreviated because the text column is 78px -- "Security updates" does
    // not fit beside the rail at any size worth reading.
    readonly property string rungText: root.level >= 4 ? "security" : "updates"

    // The parts of the answer, in the order they are worth acting on. Built as
    // a list so the tooltip never prints a source with nothing waiting -- a
    // line reading "0 packages" is noise on a layer that exists to be precise.
    readonly property var parts: {
        var out = [];
        // Security leads, in the ladder's own order, so the line that changes
        // what you do is the first one read.
        //
        // It is a line of its own rather than a qualifier on the package line
        // below, which is the record's call. The cost is worth naming because
        // nothing in the tooltip now pays it off: this count is a SUBSET of
        // the Arch line under it, so three security fixes among seventy-one
        // packages list as "3" and "71" with no indication that the 3 are
        // among the 71. A reader who adds them gets 74, and there is no total
        // on screen to contradict them -- the summary line that used to sit
        // above this list was removed as redundant with the card, and the
        // card shows the security count rather than the roll-up while this
        // rung is lit.
        //
        // Left as it is deliberately. If it reads wrong in practice the fix
        // is wording rather than structure: "3 of them security" says the
        // same thing and cannot be added up.
        if (Maintenance.archSecurity > 0)
            out.push(Maintenance.archSecurity + (Maintenance.archSecurity === 1 ? " security update" : " security updates"));
        // "Arch" rather than a bare "package": the line above it counts
        // packages too, and the two below count handaan's own work, so the
        // word on its own would not say which of them this is. Covers the AUR
        // as well as the repos -- both are packages pacman is holding.
        if (Maintenance.arch > 0)
            out.push(Maintenance.arch + (Maintenance.arch === 1 ? " Arch Package update" : " Arch Package updates"));
        if (Maintenance.handaanCommits > 0)
            out.push(Maintenance.handaanCommits + (Maintenance.handaanCommits === 1 ? " handaan commit" : " handaan commits"));
        if (Maintenance.handaanMigrations > 0)
            out.push(Maintenance.handaanMigrations + (Maintenance.handaanMigrations === 1 ? " migration" : " migrations"));
        return out;
    }

    // Named rather than listed: which check is blind is the useful half, and a
    // machine with no checkupdates would otherwise show a tooltip that quietly
    // undercounts with no sign of it.
    readonly property string blind: {
        var out = [];
        if (!Maintenance.known(Maintenance.arch))
            out.push("packages");
        // Named separately from packages because it fails separately: the
        // package count can be perfectly good while this one is unknown, which
        // is what a machine without arch-audit looks like. Saying so is the
        // difference between "no security fixes waiting" and "never checked",
        // and the card is up for other reasons in exactly that case.
        if (!Maintenance.known(Maintenance.archSecurity))
            out.push("security");
        if (!Maintenance.known(Maintenance.handaanCommits))
            out.push("handaan");
        if (out.length === 0)
            return "";
        return "Could not check: " + out.join(", ");
    }

    // Detail on request, and only ever the same question at higher
    // resolution: the glance layer said how many are waiting, this says of
    // what. Nothing here is required to read the widget.
    //
    // It opens on the breakdown rather than on a total. There used to be a
    // "71 updates waiting" line above it, written when the card was a bare
    // glyph and the total existed nowhere else. The card carries that number
    // now, so the line restated what the pointer was already sitting on --
    // the same trade the battery makes by leading with its estimate instead
    // of its percentage.
    //
    // The blind notice goes in `detail` rather than being appended to the
    // list: it is muted and a size down there, which is what it should be
    // beside counts that were actually measured.
    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.parts.join("\n")
        detail: root.blind
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

    // Battery's shape rather than Network's: the value leads at full contrast
    // and the line under it is the advice, tinted by the same ladder as the
    // glyph, because this widget ranks by severity the way the battery does
    // rather than labelling a value the way Network does.
    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical

        lineOne: root.countText
        lineTwo: root.rungText
        lineTwoColor: root.tint

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
                running: root.level >= 4
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
}
