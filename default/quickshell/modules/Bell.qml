// Notification bell.
//
// The design record is docs/quickshell/widgets/notification-bell.md -- the two
// questions this answers, the channel each one gets, and why presence rather
// than a count is the first of them. Only the implementation reasoning is
// here, and most of it sits at the declarations below.

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
            text: root.quiet ? "\uf1f6" : "\uf0f3"
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
