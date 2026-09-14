// Notifications.
//
// Two questions, per docs/quickshell-widgets.md:
//   1. Did something notify me that I have not seen?
//   2. Am I going to be told when something does?
//
// Always on the bar. It is also the way into the history, and a door that
// disappears whenever there is nothing new is one you have to remember exists.
// So presence carries nothing here; each question gets one channel of its own
// instead, and the two can be read at once without competing:
//
//   shape   bell, or bell with a slash while do-not-disturb is on
//   colour  the accent while something is unseen, grey otherwise
//
// Grey means "nothing new", not "nothing kept": opening the history is reading
// it, so notifications still in there once you have looked do not colour it.
//
// No count on the glance layer. One unseen notification and six both mean
// "open the history when you get a moment"; the figure is on hover.
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

    readonly property bool unseen: NotificationCenter.unseen > 0
    readonly property bool quiet: NotificationCenter.doNotDisturb

    implicitWidth: icon.implicitWidth

    readonly property string summary: {
        const n = NotificationCenter.unseen;
        const count = n === 0 ? "No new notifications" : n + (n === 1 ? " unseen notification" : " unseen notifications");
        return root.quiet ? "Do not disturb · " + count : count;
    }

    readonly property string detail: {
        var lines = [];
        const kept = NotificationCenter.history.length;
        if (kept > 0 && NotificationCenter.unseen === 0)
            lines.push(kept + " in history");
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

    Text {
        id: icon
        anchors.centerIn: parent
        // Nerd Font U+F1F6 bell slash, U+F0F3 bell. Escaped so the glyphs
        // survive edits; see modules/Updates.qml for what losing one cost.
        text: root.quiet ? "\uf1f6" : "\uf0f3"
        color: root.unseen ? Theme.active : Theme.barTextMuted
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * 1.12)

        Behavior on color {
            ColorAnimation {
                duration: Style.animationFast
            }
        }
    }
}
