// Clock.
//
// Two questions, per docs/quickshell-widgets.md:
//   1. What time is it?
//   2. What is today's date?
//
// A clock is unusual for this bar: it has no states. Nothing about it is ever
// urgent, nothing needs a response, and there is no "which one, right now" to
// answer. So the section on states competing for legibility applies to its
// *fields* instead. The time is what you look at many times an hour and the
// date is what you look at a few times a day, so the time is given full
// contrast and the date recedes to muted. Same principle, different axis.
//
// No seconds. A digit that changes every second is sustained change in the
// bar, and sustained change is the one channel reserved for "this needs a
// response". Spending it on a clock that is never urgent is exactly the
// permanent animation the doc warns trains you to ignore the signal. It would
// also wake the process sixty times as often for information that changes no
// decision -- you do not act on the difference between 12:35:10 and 12:35:40.
//
// The format is ISO, matching the `date '+%Y-%m-%d %H:%M'` the waybar config
// used before this. It sorts, it is unambiguous about day-vs-month, and it
// reads the same way as everything else in a terminal-first setup.
//
// There is no click handler. A clock has no obvious action, and the
// conventional one -- a calendar popup -- would be a second interface in the
// bar for something `cal` already does better.
//
// SystemClock rather than a Timer: it wakes on the minute boundary instead of
// polling, so it neither drifts nor spins between ticks.

import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "clock"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The full ISO date on both bars. It was cut to month-and-day on a side
    // bar for width, back when each widget was centred on its own content and
    // the date had the whole bar to fit across. The card gives it a fixed
    // text column instead -- Style.barCardText, 78px against the 66px ten
    // monospace characters need at this size -- so the year fits and there is
    // nothing left to buy by dropping it.
    readonly property string dateText: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    // The weekday is the one thing the ISO form cannot tell you, which is what
    // makes it the right thing to put on hover: the same question -- what is
    // today's date -- answered more fully, never a new one.
    readonly property string longDate: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")

    implicitWidth: card.implicitWidth

    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.longDate
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Date then time either way: on a side bar the same order reads top to
    // bottom. The date keeps the muted colour and the smaller size that mark
    // it as the secondary field.
    //
    // The only card with no icon. Its rail is empty and still reserved, which
    // is the standard doing its job rather than a gap in it: the date starts
    // at the same x as the battery's percentage, and the column reads as one
    // set. A glyph here would be decoration -- a clock face next to a time
    // answers nothing the time did not already say, and the doc's rule is to
    // question every element that is drawn.
    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical

        lineOne: root.dateText
        lineOneColor: Theme.barTextMuted
        lineOneSize: root.vertical ? Style.fontSizeSmall : Style.fontSize

        lineTwo: root.timeText
        lineTwoColor: root.foreground
        lineTwoSize: Style.fontSize
    }
}
