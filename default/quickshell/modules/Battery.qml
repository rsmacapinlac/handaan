// Battery.
//
// Two questions, per docs/quickshell-widgets.md:
//   1. Do I need to plug in?
//   2. Am I gaining charge, holding, or running down?
//
// One channel per question, so neither answer has to be read out of the
// other. Fill length and colour answer the first; the glyph answers the
// second, and sits outside the battery body so it never competes with the
// colour that carries severity.
//
// The second question used to be "am I on mains", answered by the presence of
// a bolt. That conflated two situations worth telling apart: a charger that
// is filling the battery, and one that is connected but delivering nothing.
// The second is common -- an underpowered supply, a cable that negotiated a
// low USB-C contract, a threshold, a firmware inhibit -- and it looks exactly
// like charging if the only signal is "something is plugged in", while the
// battery quietly drains. So the glyph now distinguishes them: a green bolt
// means gaining, a muted plug means connected but static. The widget does not
// try to say *which* cause; from here they are indistinguishable, and the
// glyph reports what is observable.
//
// Whether there is a numeral depends on which bar this is, and it is the one
// thing here decided by room rather than by the question.
//
// On a top bar there is none. Fill length and the colour ladder already answer
// "do I need to plug in", a digit beside them is a fourth thing to parse that
// changes no decision the shape did not already prompt, and dropping it is
// what bought the width the body spends on fill range -- which is what makes
// the shape answer legible at all.
//
// A side bar has no such trade to make. The body is 30px in a bar over three
// times that wide, so the numeral costs width nothing else was going to use.
// And 40% and 25% are both peach while only one of them sends you looking for
// a cable: that precision sits on hover elsewhere because hover is usually the
// only place there is for it, not because it belongs behind the pointer.
//
// So the boundary between the two layers moves and the rule does not. Where
// the numeral is on the bar, the tooltip stops restating it and leads with the
// estimate instead; hover still only ever sharpens what the shape already
// said, and nothing below the pointer is required to read the widget either
// way. docs/quickshell-widgets.md has the layers; where this widget puts the
// boundary between them is recorded here rather than there.
//
// Nothing is clickable. There is no obvious action for "the battery is at
// 40%", and a widget without one does not need a click handler. Power actions live behind the keyboard, not in the bar.
//
// The service connects lazily: UPower's fields read empty until a QML binding
// reads them, because the read is what opens the D-Bus connection. Everything
// below is a declarative binding for that reason -- a one-shot read in
// Component.onCompleted would see zeroes and latch there.

import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "battery"

    readonly property var device: UPower.displayDevice

    // A desktop and an LXC container both have a displayDevice; neither has a
    // battery behind it. Drawing an empty husk there would answer no question,
    // so the widget leaves the row entirely.
    readonly property bool present: device !== null && device.ready && device.isLaptopBattery && device.isPresent

    // percentage is a 0..1 fraction, not 0..100.
    readonly property real charge: device !== null ? Math.max(0, Math.min(1, device.percentage)) : 0

    // The system-wide flag, rather than the device's charge state. Q2 asks
    // whether mains is attached, and onBattery answers exactly that -- where
    // the device state splits the same fact across Charging, FullyCharged and
    // PendingCharge, three values to distinguish for one binary answer.
    // Not named `state`: Item already has one, and it is a string.
    readonly property int chargeState: device !== null ? device.state : UPowerDeviceState.Unknown

    readonly property bool onMains: device !== null && !UPower.onBattery

    // Actually taking charge, as opposed to merely connected. FullyCharged and
    // PendingCharge are both "connected, gaining nothing" and read as the plug.
    readonly property bool charging: root.chargeState === UPowerDeviceState.Charging

    // Carried over from the waybar config this replaces, so the levels that
    // used to mean something still do.
    readonly property real warnLevel: setting("warnLevel", 0.30)
    readonly property real criticalLevel: setting("criticalLevel", 0.15)

    // Severity only applies on battery. Plugged in at 10% is recovering, not
    // failing, and colouring it red would train the red to be ignored.
    readonly property bool low: !onMains && charge <= warnLevel
    readonly property bool critical: !onMains && charge <= criticalLevel

    // Seconds until the battery is flat, or until it is full on mains. UPower
    // reports 0 when it has no estimate yet -- just after a plug event, or
    // while the draw rate is still settling after a load change.
    readonly property real secondsLeft: {
        if (device === null)
            return 0;
        return root.onMains ? device.timeToFull : device.timeToEmpty;
    }

    readonly property string estimate: {
        if (device === null)
            return "";
        if (root.chargeState === UPowerDeviceState.FullyCharged || (root.onMains && root.charge >= 0.995))
            return "Fully charged";
        // Connected but gaining nothing: rate and both time estimates sit at
        // 0 and stay there. Falling through to "Estimating" would promise a
        // figure that is never coming, which reads as working and is a lie.
        //
        // No attempt is made to say why. A charge threshold, a firmware
        // inhibit and a supply too weak to charge are indistinguishable from
        // here -- all three are pending-charge at a zero rate -- so the line
        // states the observable fact and leaves the diagnosis to the person.
        //
        // The wording is about charging rather than about mains, because the
        // glyph has already said something is plugged in; restating it would
        // spend a line on what the glance layer answered.
        if (root.chargeState === UPowerDeviceState.PendingCharge)
            return "Not charging";
        if (root.secondsLeft <= 0)
            return "Estimating\u2026";
        return root.formatDuration(root.secondsLeft) + (root.onMains ? " until full" : " remaining");
    }

    // Rounded to the minute. A seconds field on a figure this noisy would be
    // false precision.
    function formatDuration(seconds) {
        var minutes = Math.round(seconds / 60);
        var hours = Math.floor(minutes / 60);
        var rest = minutes % 60;
        if (hours > 0)
            return hours + "h " + (rest < 10 ? "0" : "") + rest + "m";
        return rest + "m";
    }

    // Rounded to the whole point. 68.4% and 68% prompt the same decision, and
    // a decimal here would be the false precision formatDuration already
    // refuses on the figure beside it.
    readonly property string percentText: Math.round(root.charge * 100) + "%"

    readonly property color tint: {
        if (root.critical)
            return Theme.critical;
        if (root.low)
            return Theme.warning;
        return Theme.barTextMuted;
    }

    // ------------------------------------------------------------- geometry
    // On a top bar, wider than a battery glyph would be, because fill length
    // is the only thing encoding how much is left: every pixel of body is
    // resolution on the widget's primary question.
    //
    // On a side bar it is the card's icon rail instead, which is narrower --
    // and that is the same argument rather than an exception to it. Fill
    // length is no longer the only encoding there: the numeral is beside it,
    // so the pixels the body gives up are pixels whose resolution is now
    // carried in a form that does not need them. The rail is sized from this
    // body in the first place, so the two cannot drift apart.
    readonly property int bodyWidth: root.vertical ? Style.barCardRail - root.capWidth : Style.space(7)
    readonly property int bodyHeight: Style.space(3.5)
    readonly property int capWidth: Style.space(0.5)
    readonly property int capHeight: Style.space(1.5)
    readonly property int fillInset: Style.space(0.5)

    active: present
    implicitWidth: card.implicitWidth

    // Measured rather than assumed: the two glyphs are not the same advance
    // width in this font (9px against 8px), so the slot takes the larger.
    TextMetrics {
        id: boltMetrics
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        text: ""
    }

    TextMetrics {
        id: plugMetrics
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        text: ""
    }

    // Detail on demand: the exact charge, and how long it buys you. Both are
    // redundant -- the fill length and the bolt already answered the widget's
    // two questions -- which is the only reason they are allowed here.
    //
    // On a side bar the charge is on the bar, so a tooltip opening with it
    // would restate what the pointer is sitting next to. The estimate takes
    // the top line there instead: the same question still, still sharper than
    // the shape, and the only half of the pair the glance layer cannot give.
    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.vertical ? root.estimate : root.percentText
        detail: root.vertical ? "" : root.estimate
    }

    // Hover only. There is no click action, and swallowing button presses over
    // the bar for a widget that does nothing with them would be rude.
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Bolt or plug, as the card's accessory rather than as a column of the
    // row. Null when there is no supply attached, which is what collapses the
    // slot: a Loader with no component takes no width.
    //
    // That collapse is the same trade the row made before the card, and it
    // still costs the same thing -- the glyph appearing on a dock shifts what
    // is beside it -- judged against a permanently reserved slot leaving a
    // hole in the card in every state but one. What it did lose is the fade:
    // the glyph used to cross-fade in and now it is created and destroyed
    // with the supply. Worth restoring if the appearance ever reads as a jump
    // rather than as a plug going in.
    Component {
        id: chargeGlyph

        Item {
            implicitWidth: Math.max(boltMetrics.width, plugMetrics.width)
            implicitHeight: indicator.implicitHeight

            Text {
                id: indicator

                anchors.centerIn: parent
                // Nerd Font U+F0E7 bolt when gaining charge, U+F1E6 plug when
                // merely connected. Escaped rather than written literally --
                // see modules/Updates.qml for what losing a private-use
                // codepoint to a rewrite cost once already.
                text: root.charging ? "\uf0e7" : "\uf1e6"
                // Green is reserved for the good case, so a plug cannot be
                // mistaken for one at a glance; connected-but-static is a
                // neutral fact, not a reassurance. This is why the glyph is an
                // accessory item rather than part of the line's string: one
                // Text cannot be green while the numeral beside it is on the
                // severity ladder.
                color: root.charging ? Theme.good : Theme.barTextMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }
            }
        }
    }

    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical
        // The numeral only exists on a side bar. See the header for why the
        // top bar keeps the shape alone.
        lineOne: root.vertical ? root.percentText : ""
        // Tinted with the body rather than given a colour of its own, so it
        // joins the existing ladder instead of opening a fourth channel: the
        // numeral is the same answer at higher resolution and should look
        // like it.
        lineOneColor: root.tint
        accessory: root.present && root.onMains ? chargeGlyph : null

        // The icon. Centred in the card's rail, which is sized from it, and
        // deliberately outside the line beside it: the shape pulses and the
        // figure holds still, so the motion reads as one thing moving rather
        // than the whole card breathing.
        Item {
            id: graphic

            anchors.centerIn: parent
            width: root.bodyWidth + root.capWidth
            height: root.bodyHeight

            // Motion means "this needs a response", and it stops when the
            // condition clears. Critical *and* discharging is the only state
            // here that qualifies: on mains at 10% the battery is recovering
            // and needs nothing from you, so it stays still. The same cycle
            // and amplitude as the workspace pulse, so the bar has one
            // vocabulary for urgency rather than two.
            //
            // An urgent workspace could in principle pulse at the same moment.
            // Both are genuinely "needs a response" and neither is worth
            // demoting to avoid a collision that requires a window shouting
            // while the battery is nearly flat.
            SequentialAnimation on scale {
                running: root.critical
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

            Rectangle {
                id: body

                width: root.bodyWidth
                height: root.bodyHeight
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: Style.space(1)
                color: "transparent"
                border.width: Style.borderWidth
                border.color: root.tint

                Behavior on border.color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }

                Rectangle {
                    id: fill

                    anchors.left: parent.left
                    anchors.leftMargin: root.fillInset
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height - root.fillInset * 2
                    // Floored so a nearly-dead battery still draws a sliver:
                    // an empty outline reads as "no data", which is a
                    // different and much less alarming thing than "no charge".
                    width: Math.max(Style.space(0.5), (parent.width - root.fillInset * 2) * root.charge)
                    radius: Style.space(0.5)
                    color: root.tint

                    Behavior on width {
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
                }
            }

            Rectangle {
                id: cap

                width: root.capWidth
                height: root.capHeight
                anchors.left: body.right
                anchors.verticalCenter: parent.verticalCenter
                radius: Style.borderWidth
                color: root.tint

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }
            }
        }
    }
}
