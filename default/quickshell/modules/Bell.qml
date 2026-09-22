// Notifications.
//
// Two questions, per docs/quickshell-widgets.md:
//   1. Is anything waiting for me, and how much does it matter?
//   2. Am I going to be told when something new arrives?
//
// Each question gets one channel of its own, so the two can be read at once
// without competing:
//
//   presence  the bell is on the bar while anything is kept in history
//   colour    the most urgent thing kept: critical red, normal the accent,
//             low grey
//   shape     a slashed bell while do-not-disturb is on
//
// Presence is Updates' encoding: a machine with nothing waiting has no
// notification chrome on it at all. Waiting means kept, not unseen -- opening
// the history marks everything seen, and a bell that vanished the moment you
// looked would leave what you have not dealt with behind a door you have to
// remember exists. Dismiss it or clear the history and the bell goes.
//
// Do-not-disturb holds the bell up on its own, grey when nothing is kept. Being
// quiet is the one state you must not forget you are in, and an empty bar
// cannot say it. Turn it off with nothing kept and the bell goes too.
//
// Colour is the highest urgency kept rather than the newest, so a critical
// notification is not hidden by a chatty app arriving after it. Peach is left
// out on purpose: it is Network's and Battery's warning, and a normal
// notification is not a warning.
//
// No count on the glance layer. One notification and six both mean "open the
// history when you get a moment"; the figures are on hover.
//
// Nothing moves. A notification that needed a response now was critical, and
// critical already stays on screen until dismissed -- a pulse here would be a
// second holder of the attention channel saying less than the popup does.
//
// Click opens the history, which is the obvious action for either question
// and destroys nothing.

import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "bell"

    readonly property bool quiet: NotificationCenter.doNotDisturb

    active: NotificationCenter.history.length > 0 || root.quiet

    // A card. No line beside the glyph: one notification and six ask the same
    // thing of you, which the rail having room does not change.
    implicitWidth: card.implicitWidth

    // How many kept notifications are at each urgency, read once per change
    // to the history rather than once per property that wants a figure.
    readonly property var counts: {
        var out = { critical: 0, normal: 0, low: 0 };
        for (var i = 0; i < NotificationCenter.history.length; i++)
            out[NotificationCenter.history[i].urgency] += 1;
        return out;
    }

    readonly property color tint: {
        if (root.counts.critical > 0)
            return Theme.critical;
        if (root.counts.normal > 0)
            return Theme.active;
        return Theme.barTextMuted;
    }

    readonly property string summary: {
        const n = NotificationCenter.history.length;
        const count = n === 0 ? "No notifications" : n + (n === 1 ? " notification" : " notifications");
        return root.quiet ? "Do not disturb · " + count : count;
    }

    // The same question at higher resolution: what is waiting, by urgency, and
    // how much of it you have not looked at yet.
    readonly property string detail: {
        var lines = [];
        if (root.counts.critical > 0)
            lines.push(root.counts.critical + " critical");
        if (root.counts.normal > 0 && (root.counts.critical > 0 || root.counts.low > 0))
            lines.push(root.counts.normal + " normal");
        if (root.counts.low > 0 && (root.counts.critical > 0 || root.counts.normal > 0))
            lines.push(root.counts.low + " low");
        if (NotificationCenter.unseen > 0)
            lines.push(NotificationCenter.unseen + " unseen");
        if (root.quiet)
            lines.push("Only critical notifications pop up");
        return lines.join("\n");
    }

    Tooltip {
        anchorItem: root
        open: hover.containsMouse
        text: root.summary
        detail: root.detail
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -Style.widgetPadding
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: NotificationCenter.toggleHistory()
    }

    BarCard {
        id: card

        anchors.fill: parent
        vertical: root.vertical

        Text {
            id: icon
            anchors.centerIn: parent
            // Nerd Font U+F1F6 bell slash, U+F0F3 bell. Escaped so the glyphs
            // survive edits; see modules/Updates.qml for what losing one cost.
            text: root.quiet ? "" : ""
            color: root.tint
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * 1.12)

            Behavior on color {
                ColorAnimation {
                    duration: Style.animationFast
                }
            }

            // A transition, not motion: the bell fading in as the first
            // notification lands reads as an arrival rather than a glyph you had
            // missed. The same beat Updates uses.
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
