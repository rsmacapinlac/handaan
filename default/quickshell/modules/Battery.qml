// Battery.
//
// The design record is docs/quickshell/widgets/battery.md -- the two questions
// this answers, the channel each one gets, why the glyph distinguishes gaining
// from merely connected, and why the numeral comes and goes with the bar's
// edge. Only the implementation reasoning is here.
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
    // battery behind it.
    readonly property bool present: device !== null && device.ready && device.isLaptopBattery && device.isPresent

    // percentage is a 0..1 fraction, not 0..100.
    readonly property real charge: device !== null ? Math.max(0, Math.min(1, device.percentage)) : 0

    // Not named `state`: Item already has one, and it is a string.
    readonly property int chargeState: device !== null ? device.state : UPowerDeviceState.Unknown

    // The system-wide flag rather than the device's charge state, which splits
    // the same fact across Charging, FullyCharged and PendingCharge.
    readonly property bool onMains: device !== null && !UPower.onBattery

    // The four states. Charging is actually gaining; fullyCharged is done;
    // pluggedIdle is connected and gaining nothing; discharging is !onMains.
    readonly property bool charging: root.chargeState === UPowerDeviceState.Charging
    readonly property bool fullyCharged: root.chargeState === UPowerDeviceState.FullyCharged || (root.onMains && root.charge >= 0.995)
    readonly property bool pluggedIdle: root.onMains && !root.charging && !root.fullyCharged

    // Carried over from the waybar config this replaces, so the levels that
    // used to mean something still do.
    readonly property real warnLevel: setting("warnLevel", 0.30)
    readonly property real criticalLevel: setting("criticalLevel", 0.15)

    // Severity only applies on battery, which is what keeps it from ever
    // colliding with the two green states below: on mains there is nothing to
    // act on, so the colour is free to answer the other question.
    readonly property bool low: !onMains && charge <= warnLevel
    readonly property bool critical: !onMains && charge <= criticalLevel

    // Seconds until flat, or until full on mains. UPower reports 0 when it has
    // no estimate yet -- just after a plug event, or while the draw rate is
    // still settling after a load change.
    readonly property real secondsLeft: {
        if (device === null)
            return 0;
        return root.onMains ? device.timeToFull : device.timeToEmpty;
    }

    readonly property string estimate: {
        if (device === null)
            return "";
        if (root.fullyCharged)
            return "Fully charged";
        // Connected but gaining nothing: rate and both time estimates sit at 0
        // and stay there. Falling through to "Estimating" would promise a
        // figure that is never coming, which reads as working and is a lie.
        if (root.pluggedIdle && root.secondsLeft <= 0)
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

    // Rounded to the whole point: 68.4% and 68% prompt the same decision.
    readonly property string percentText: Math.round(root.charge * 100) + "%"

    // Severity first, state second. The record has the ordering: colour says
    // what the battery is doing until there is something to do about it, and
    // then it says that instead.
    readonly property color tint: {
        if (root.critical)
            return Theme.critical;
        if (root.low)
            return Theme.warning;
        if (root.charging || root.fullyCharged)
            return Theme.good;
        return Theme.barTextMuted;
    }

    // Nerd Font U+F0E7 bolt, U+F1E6 plug. Escaped rather than written
    // literally -- see modules/Updates.qml for what losing a private-use
    // codepoint to a rewrite cost once already. Discharging has no glyph:
    // nothing is attached, and an icon for "no supply" would be one.
    readonly property string stateGlyph: {
        if (root.charging)
            return "\uf0e7";
        if (root.onMains)
            return "\uf1e6";
        return "";
    }

    // What to do about it, or nothing. The card drops an empty line entirely,
    // so a battery with no action on it is a single-line card.
    readonly property string advice: {
        if (root.critical)
            return "Plug in now";
        if (root.low)
            return "Plug in";
        return "";
    }

    // ------------------------------------------------------------- geometry
    readonly property int bodyWidth: root.vertical ? Style.barCardRail - root.capWidth : Style.space(7)
    readonly property int bodyHeight: Style.space(3.5)
    readonly property int capWidth: Style.space(0.5)
    readonly property int capHeight: Style.space(1.5)
    readonly property int fillInset: Style.space(0.5)

    active: present
    implicitWidth: card.implicitWidth

    // The percentage is on the bar in every state now, so the tooltip leads
    // with the estimate: restating what the pointer is sitting next to would
    // spend the hover layer on nothing.
    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.estimate
    }

    // Hover only. There is no click action, and swallowing button presses over
    // the bar for a widget that does nothing with them would be rude.
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

        lineOne: root.percentText
        // Plain. The icon owns colour now, and a numeral repeating it would be
        // the same channel twice rather than a second reading.
        lineOneColor: root.foreground
        lineTwo: root.advice
        // Only ever set while low or critical, so this is always the severity
        // colour and never the state one.
        lineTwoColor: root.tint

        // The icon, centred in the card's rail, which is sized from it. The
        // shape pulses and the numeral holds still, so the motion reads as one
        // thing moving rather than the whole card breathing.
        Item {
            id: graphic

            anchors.centerIn: parent
            width: root.bodyWidth + root.capWidth
            height: root.bodyHeight

            // Critical and discharging only, on the bar's one 620ms cycle for
            // urgency. The record has why that is the single state here that
            // earns the motion channel, and what it accepts by sharing it.
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
                    // Floored so a nearly-flat battery still draws a sliver: an
                    // empty outline reads as "no data", which is a different and
                    // much less alarming thing than "no charge".
                    width: Math.max(Style.space(0.5), (parent.width - root.fillInset * 2) * root.charge)
                    radius: Style.space(0.5)
                    color: root.tint
                    // Drops back to a band whenever a glyph is sitting on it,
                    // which is exactly when the glyph is the answer and the
                    // level is context: on mains the numeral has the figure.
                    // Discharging carries no glyph and keeps the solid fill,
                    // which is when the level is what you are reading.
                    opacity: root.stateGlyph !== "" ? 0.4 : 1.0

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
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.animationFast
                        }
                    }
                }

                // Inside the body rather than beside it, so the icon carries
                // the state instead of introducing it. Drawn at full tint over
                // the dimmed fill, which is what keeps it legible whether the
                // battery is nearly empty or nearly full.
                Text {
                    id: stateIcon

                    anchors.centerIn: parent
                    text: root.stateGlyph
                    color: root.tint
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(root.bodyHeight * 0.72)

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
