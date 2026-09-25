// The bar's centre section. See docs/island/README.md.
//
// Not a widget and not a card: a widget is a fixed question in a fixed place
// that you read, and this is a place you act in, holding whatever is currently
// going on. docs/bar.md has why that difference is worth three sections rather
// than one design language.
//
// Drawn in the bar's own window so the cut-out grows into the expanded
// surface. The bar reserves the same strip at either size; see Bar.qml.
//
// The cut-out is always present, including when nothing is going on. That is
// the one thing on the bar that is permanent without answering a question, and
// it earns it by not being information: it is the handle, and settings are
// always reachable through it.
//
// Two occupants so far, and they behave differently in time. Media is the
// resting state: it is there for hours and it is still there afterwards. A
// notification is an event -- it takes the island, and when it is done the
// island goes back to whatever it was showing. So notifications win while they
// last, which is the whole of the precedence rule for now.
//
// Its notifications are the same set NotificationCenter puts on screen, read
// straight off `popups`. That is deliberate: the centre already decides what
// pops, for how long, what do-not-disturb holds back, what the lock screen
// suppresses, and that critical stays until dismissed. None of that is worth
// a second implementation here, and a second one would drift.
//
// The popups still appear as well. That contradicts this section's own rule
// that it is not a second place to say something the bar already says, and it
// is deliberate and temporary -- both run so they can be compared before one
// is retired, the way Waybar stayed installed beside the Quickshell bar. See
// docs/island/README.md.
//
// Clicking the cut-out expands it; clicking away collapses it. Moving the
// pointer does neither. Bar.qml handles outside clicks, including those on
// other windows, while controls inside the island keep their own actions.
//
// Only horizontal bars have one. What a side bar should do is open -- its
// centre is the middle of a screen edge and its budget is the card text column
// -- so rather than guess, this draws nothing when vertical.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Item {
    id: root

    // Set by the bar. The island is a horizontal-bar thing for now.
    property bool vertical: false

    // How much taller than the bar the window has to be to hold this. Read by
    // Bar.qml, which grows the window by it while keeping the reserved strip
    // at barSize so no window on the screen moves.
    readonly property int overflow: Math.max(0, root.implicitHeight - Style.barSize)

    // What the bar masks in, beyond the bar strip itself. Everything else in
    // the grown window is transparent and must not take the pointer.
    readonly property Item hitArea: shape

    // The player worth speaking for: whichever is actually playing, else the
    // first that exists, else none. Session-wide on purpose -- every monitor's
    // island is a view onto the same player, so this must not be per screen.
    readonly property var player: {
        const all = Mpris.players.values;
        for (var i = 0; i < all.length; i++) {
            if (all[i].isPlaying)
                return all[i];
        }
        return all.length > 0 ? all[0] : null;
    }

    readonly property bool hasMedia: root.player !== null

    // The newest thing on screen, or nothing. NotificationCenter keeps these
    // newest-first and drops them on its own schedule, so the island needs no
    // timer of its own.
    readonly property var notification: NotificationCenter.popups.length > 0 ? NotificationCenter.popups[0].record : null

    readonly property bool hasNotification: root.notification !== null

    // An event outranks a state. When the notification goes, media is still
    // underneath it.
    readonly property string occupant: root.hasNotification ? "notification" : (root.hasMedia ? "media" : "none")

    // What the bell used to answer, folded in here: what is waiting that you
    // have not dealt with, and whether you will be told about the next thing.
    //
    // It is a badge rather than an occupant, and that distinction is the whole
    // of why. The occupants are things happening now and they take turns; a
    // backlog is not happening, it is outstanding, and it has to still be
    // there while something else is in the island. An occupant would vanish
    // the moment media started playing.
    //
    // Waiting means kept, not unseen: reading the history does not clear this,
    // only dismissing or clearing does. A badge that went away when you looked
    // would hide what you have not dealt with behind a door you have to
    // remember exists.
    readonly property bool quiet: NotificationCenter.doNotDisturb

    readonly property var kept: {
        var out = { critical: 0, normal: 0, low: 0 };
        for (var i = 0; i < NotificationCenter.history.length; i++)
            out[NotificationCenter.history[i].urgency] += 1;
        return out;
    }

    readonly property bool hasBacklog: NotificationCenter.history.length > 0 || root.quiet

    // What the island holds. A popup is the announcement; when it times out
    // the notification has not gone anywhere, it is kept -- so it is in here,
    // and opening the island is how you get back to it.
    //
    // All of them, not a sample. The island is where notifications live, so a
    // stack that stopped at three and said "more waiting" was telling you
    // there was somewhere else to go -- and there should not be.
    //
    // Size the viewport from the first four cards; the rest remain reachable
    // by scrolling. The pixel ceiling still protects against very tall cards.
    readonly property var stacked: NotificationCenter.history

    // Taken from the most urgent kept rather than the newest, so a chatty app
    // cannot bury a critical one. Peach is deliberately not used: it is
    // Network's and Battery's warning, and a notification is not a warning.
    readonly property color backlogTint: {
        if (root.kept.critical > 0)
            return Theme.critical;
        if (root.kept.normal > 0)
            return Theme.active;
        return Theme.barTextMuted;
    }

    // The cut-out's own height: the bar's thickness less the inset that keeps
    // the bar's surface visible around it.
    readonly property int cutoutHeight: Style.barSize - Style.space(2)

    property bool expanded: false

    onVerticalChanged: {
        if (root.vertical)
            root.expanded = false;
    }

    // What the cut-out answers on its own: who is telling you something, or
    // what is playing. Detail is the expanded state's job.
    readonly property string cutoutText: {
        if (root.occupant === "notification")
            return root.notification.summary !== "" ? root.notification.summary : root.notification.appName;
        if (root.occupant === "media") {
            const t = root.player.trackTitle;
            return t && t !== "" ? t : root.player.identity;
        }
        return "";
    }

    // Nerd Font: U+F0F3 bell, U+F04B play, U+F04C pause, U+F141 ellipsis.
    // Escapes rather than the glyphs themselves -- a private-use codepoint is
    // invisible in a diff and has been lost twice in this tree already.
    readonly property string cutoutGlyph: {
        if (root.occupant === "notification")
            return "\uf0f3";
        if (root.occupant === "media")
            return root.player.isPlaying ? "\uf04b" : "\uf04c";
        return "\uf141";
    }

    // Critical is the one notification state drawn loudly, the same way the
    // card draws it.
    readonly property color cutoutTint: {
        if (root.occupant === "notification")
            return root.notification.urgency === "critical" ? Theme.critical : Theme.barText;
        if (root.occupant === "media")
            return Theme.barText;
        return Theme.barTextMuted;
    }

    implicitWidth: shape.width
    implicitHeight: shape.height + Style.space(1)
    visible: !root.vertical

    // A labelled control in the expanded half, for the two things that act on
    // the whole set rather than on one notification.
    component IslandChip: Rectangle {
        id: chip

        required property string label
        property bool on: false
        signal activated

        implicitWidth: chipText.implicitWidth + Style.space(4)
        implicitHeight: chipText.implicitHeight + Style.space(2)
        radius: Style.radius
        color: chip.on ? Theme.active : (chipHover.hovered ? Theme.surfaceHover : Theme.surface)
        border.width: Style.borderWidth
        border.color: chip.on ? Theme.active : Theme.border

        Text {
            id: chipText

            anchors.centerIn: parent
            text: chip.label
            color: chip.on ? Theme.barBackground : Theme.barText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
        }

        HoverHandler {
            id: chipHover
        }

        TapHandler {
            onTapped: chip.activated()
        }
    }

    // One control in the expanded half. Click, because this is the acting
    // layer -- the bar's rule is that click performs an action.
    component IslandButton: Text {
        id: button

        required property string glyph
        signal activated

        text: button.glyph
        color: button.enabled ? Theme.barText : Theme.barTextMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        Layout.alignment: Qt.AlignVCenter

        TapHandler {
            enabled: button.enabled
            onTapped: button.activated()
        }
    }
    // The shape is the island: one rectangle that changes size, rather than a
    // notch plus a panel. Its top edge stays in the bar and it grows downward.
    Rectangle {
        id: shape

        anchors.top: parent.top
        anchors.topMargin: Style.space(1)
        anchors.horizontalCenter: parent.horizontalCenter

        // Leaves the bar's own surface visible around it, so the shape reads
        // as cut into the bar rather than laid on top of it.
        implicitWidth: root.expanded ? Style.islandWidth : cutout.implicitWidth + Style.space(3) * 2
        implicitHeight: root.cutoutHeight + (root.expanded ? panel.implicitHeight + Style.space(3) : 0)
        width: implicitWidth
        height: implicitHeight

        // A capsule when small; squarer once it is a window, because a fully
        // rounded panel reads as a lozenge rather than something you can put
        // controls in.
        radius: root.expanded ? Style.radius * 2 : height / 2
        color: Theme.barBackground

        Behavior on width {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        // The whole collapsed shape is clickable, including its padding.
        MouseArea {
            anchors.fill: parent
            enabled: !root.expanded
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }

        // The cut-out's own line, held at the top of the shape so it stays
        // where it was when the shape grows underneath it.
        RowLayout {
            id: cutout

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.cutoutHeight
            spacing: Style.space(1.5)

            Text {
                text: root.cutoutGlyph
                color: root.cutoutTint
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                visible: root.cutoutText !== ""
                text: root.cutoutText
                color: root.cutoutTint
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                elide: Text.ElideRight
                // A title is not a fact that has to survive whole the way an
                // address is, so it elides rather than shrinking. The ceiling
                // stops one long title pushing the bar's centre around.
                Layout.maximumWidth: Style.islandCutoutText
                Layout.alignment: Qt.AlignVCenter
            }

            // The backlog badge. Nerd Font U+F0F3 bell, U+F1F6 bell slash --
            // shape answers the second question, the way the widget did.
            Text {
                visible: root.hasBacklog
                text: root.quiet ? "\uf1f6" : "\uf0f3"
                color: root.backlogTint
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: root.cutoutText !== "" ? Style.space(1) : 0
            }


        }

        // The expanded half: what the cut-out could not say, and the controls.
        // Filled to the stated size rather than hugging its content, so the
        // window does not change shape as one track follows another.
        Item {
            id: expandedContent

            anchors.top: cutout.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.space(3)
            anchors.topMargin: 0

            opacity: root.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutCubic
                }
            }

            // One panel holding everything the island has, rather than a
            // choice between occupants. A backlog must not hide the media
            // controls: the cut-out shows one thing at a time because it has
            // room for one thing, but expanding is where you came to find
            // what else there was.
            ColumnLayout {
                id: panel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Style.space(2)

                Loader {
                    active: root.hasMedia
                    visible: active
                    sourceComponent: mediaPanel
                    Layout.fillWidth: true
                }

                // The stack. Newest first, the same card the popup was --
                // "the same card as a popup and in the history" is the
                // notification's own rule, and this is a third place it is
                // read rather than a third way of drawing it.
                ListView {
                    id: list

                    model: root.stacked
                    spacing: Style.space(2)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: root.stacked.length > 0

                    // Measure only the first four cards independently of the
                    // virtualized delegates, so scrolling cannot resize the panel.
                    implicitHeight: Math.min(preview.implicitHeight, Style.islandMaxStack)

                    Column {
                        id: preview

                        visible: false
                        width: list.width - Style.space(3)
                        spacing: list.spacing

                        Repeater {
                            model: root.stacked.slice(0, 4)

                            delegate: NotificationCard {
                                required property var modelData

                                width: preview.width
                                record: modelData
                                bodyLines: 4
                            }
                        }
                    }

                    Controls.ScrollBar.vertical: Controls.ScrollBar {
                        id: scrollBar

                        policy: Controls.ScrollBar.AsNeeded
                        visible: list.contentHeight > list.height
                        contentItem: Rectangle {
                            implicitWidth: Style.space(1)
                            radius: width / 2
                            color: scrollBar.pressed ? Theme.active : Theme.barTextMuted
                        }
                        background: Item {}
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight

                    delegate: NotificationCard {
                        id: card

                        required property var modelData

                        width: list.width - Style.space(3)
                        record: card.modelData
                        bodyLines: 4

                        onCloseClicked: NotificationCenter.dismiss(card.modelData.id)
                        onActionClicked: identifier => NotificationCenter.activate(card.modelData.id, identifier)
                        onActivated: NotificationCenter.activate(card.modelData.id, "")
                    }
                }

                // What the history panel carried, because the island is that
                // panel now: the switch for whether you will be told, and the
                // way to be done with all of it at once.
                RowLayout {
                    spacing: Style.space(2)
                    Layout.fillWidth: true

                    IslandChip {
                        label: (root.quiet ? "\uf1f6" : "\uf0f3") + "  Do not disturb"
                        on: root.quiet
                        onActivated: NotificationCenter.setDoNotDisturb(!root.quiet)
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    IslandChip {
                        visible: NotificationCenter.history.length > 0
                        label: "Clear all"
                        onActivated: NotificationCenter.clearAll()
                    }
                }

                // Said rather than left as an empty panel: do-not-disturb can
                // hold the island open with nothing in it, and that is the one
                // state you must not forget you are in.
                Text {
                    visible: NotificationCenter.history.length === 0
                    text: root.quiet ? "Nothing waiting. Do not disturb is on." : "Nothing waiting."
                    color: Theme.barTextMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Component {
        id: mediaPanel

        ColumnLayout {
            spacing: Style.space(2)

            RowLayout {
                spacing: Style.space(2.5)
                Layout.fillWidth: true

                // The art if the player offers one. Nothing is drawn when it
                // does not, rather than a placeholder standing in for an
                // answer nobody asked for.
                Rectangle {
                    visible: art.status === Image.Ready
                    implicitWidth: Style.islandArt
                    implicitHeight: Style.islandArt
                    radius: Style.radius
                    color: Theme.surface
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.hasMedia && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    spacing: Style.space(0.5)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.hasMedia ? root.player.trackArtist : ""
                        visible: text !== ""
                        color: Theme.barText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.hasMedia ? root.player.trackAlbum : ""
                        visible: text !== ""
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.hasMedia ? root.player.identity : ""
                        visible: text !== ""
                        color: Theme.barTextMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                spacing: Style.space(5)
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true

                IslandButton {
                    glyph: "\uf048"
                    enabled: root.hasMedia && root.player.canGoPrevious
                    onActivated: root.player.previous()
                }

                IslandButton {
                    glyph: root.hasMedia && root.player.isPlaying ? "\uf04c" : "\uf04b"
                    enabled: root.hasMedia && root.player.canTogglePlaying
                    onActivated: root.player.togglePlaying()
                }

                IslandButton {
                    glyph: "\uf051"
                    enabled: root.hasMedia && root.player.canGoNext
                    onActivated: root.player.next()
                }
            }
        }
    }

}
