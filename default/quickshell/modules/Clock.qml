// Clock.
//
// The design record is docs/quickshell/widgets/clock.md -- the questions this
// answers, what the glance layer carries and what hover adds. Only the
// implementation reasoning is here.
//
// SystemClock rather than a Timer: it wakes on the minute boundary instead of
// polling, so it neither drifts nor spins between ticks. Minute precision is
// also what keeps seconds off the bar.

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

    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    // Weekday and date as one field: both answer "what day is it", and they
    // share the card's one muted line. The year is off the glance layer
    // because it will not fit beside the weekday -- Style.barCardText is 78px,
    // eleven monospace characters at this size, and "Wed 2026-09-23" needs
    // fourteen. It survives on hover and in the calendar.
    readonly property string dateText: Qt.formatDateTime(clock.date, "ddd MM-dd")
    readonly property string longDate: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")

    // Changes once a day, which is what the calendar binding hangs off: bound
    // to clock.date directly it would rebuild the grid every minute.
    readonly property string dayKey: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
    readonly property string calendar: root.monthGrid(root.dayKey)

    // One day, five columns wide. The digits sit in the same two columns
    // whether or not the day is marked, and the brackets take the padding
    // either side rather than the number's own place -- right-aligning
    // "[23]" as one token shifts its digits a column left of the 16 above it
    // and the 30 below, which is the whole reason this is not a plain pad.
    function cell(value, marked) {
        if (marked)
            return ("     [" + value + "]").slice(-5);
        return ("    " + value).slice(-4) + " ";
    }

    // The current month as monospace text, Monday first to match the ISO date
    // beside it. The key is split by hand rather than handed to Date():
    // new Date("2026-09-23") parses as UTC and lands on the previous day west
    // of Greenwich.
    function monthGrid(key) {
        var parts = key.split("-");
        var year = parseInt(parts[0], 10);
        var month = parseInt(parts[1], 10) - 1;
        var today = parseInt(parts[2], 10);

        // getDay() counts from Sunday; shift it to Monday.
        var lead = (new Date(year, month, 1).getDay() + 6) % 7;
        var days = new Date(year, month + 1, 0).getDate();

        var names = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
        var head = "";
        for (var i = 0; i < 7; i++)
            head += root.cell(names[i], false);
        var lines = [head.replace(/\s+$/, "")];

        var line = "";
        for (var i = 0; i < lead; i++)
            line += root.cell("", false);
        for (var d = 1; d <= days; d++) {
            line += root.cell(d, d === today);
            if ((lead + d) % 7 === 0) {
                lines.push(line.replace(/\s+$/, ""));
                line = "";
            }
        }
        if (line !== "")
            lines.push(line.replace(/\s+$/, ""));
        return lines.join("\n");
    }

    implicitWidth: card.implicitWidth

    // The grid needs no layout: Style.fontFamily is monospace, so the columns
    // line up as text.
    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.longDate
        detail: root.calendar
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical

        // Identity only. The Clock has no state for the rail to carry -- the
        // two lines beside it already hold everything this widget answers --
        // so the glyph says which card this is and nothing more. An hour-hand
        // face was rejected rather than overlooked: it would encode the hour
        // that line two prints exactly, at a resolution 15px cannot show.
        //
        // Nerd Font U+F017: clock. Escaped rather than written literally --
        // see modules/Updates.qml for what losing a private-use codepoint to
        // a rewrite cost once already.
        Text {
            anchors.centerIn: parent
            text: "\uf017"
            color: Theme.barTextMuted
            font.family: Style.fontFamily
            // The size the bar's other bare glyphs are drawn at.
            font.pixelSize: Math.round(Style.fontSize * 1.12)
        }

        lineOne: root.dateText
        lineOneColor: Theme.barTextMuted
        lineOneSize: root.vertical ? Style.fontSizeSmall : Style.fontSize

        lineTwo: root.timeText
        lineTwoColor: root.foreground
        lineTwoSize: Style.fontSize
    }
}
