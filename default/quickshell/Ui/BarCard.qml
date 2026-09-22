// The shape a bar widget takes.
//
// One card: an icon in a fixed rail on the left, and at most two lines of text
// beside it. Every widget on a side bar is one of these, which is what makes
// the bar read as a single column rather than as a stack of unrelated
// widgets -- the rail is reserved whether or not a card has an icon, so the
// clock's date starts at the same x as the battery's percentage.
//
// Two lines is a ceiling, not a quota. A card with nothing worth saying is an
// icon and an empty text column, and that is the correct shape for it: what
// belongs on the glance layer is settled by docs/quickshell-widgets.md, and
// having somewhere to put a line is not a reason to find one. The ceiling is
// enforced rather than trusted -- there are two line properties and no third,
// and each is capped at Style.barCardText and elides -- because the failure
// this prevents is a widget that quietly grows a third line and pushes the
// bar wider for every other card at once.
//
// On a top bar the same card lays out as a row: rail, then the lines beside
// each other. That keeps each widget's content declared once rather than
// twice, at the cost of one visible change -- the accessory follows the icon
// there instead of preceding it, so the battery reads body-then-bolt rather
// than bolt-then-body. The card puts the icon first, always.

import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
    id: card

    // The icon, as the card's default children, so a widget writes its glyph
    // or its drawn shape as a plain child and nothing else. The child places
    // itself with `anchors.centerIn: parent`: the rail is a plain Item rather
    // than a layout, because the battery's icon is two rectangles that have to
    // hold their positions relative to each other.
    default property alias iconContent: rail.data

    // Set from BarWidget.vertical by every caller. Defaulted to the side bar
    // rather than the top one because that is the layout this type exists for;
    // a card that forgot to pass it should look wrong in the common case, not
    // silently correct in the rare one.
    property bool vertical: true

    // Named by position, not by importance. Line one is above line two on a
    // side bar and left of it on a top bar, and which of them carries the
    // answer differs by widget: the battery leads with its percentage, the
    // clock leads with its date and puts the time underneath. So the card
    // takes a colour and a size per line instead of ranking them itself.
    property string lineOne: ""
    property string lineTwo: ""
    property color lineOneColor: Theme.barText
    property color lineTwoColor: Theme.barTextMuted
    property int lineOneSize: Style.fontSize
    property int lineTwoSize: Style.fontSizeSmall

    // Drawn after line one, for the one thing a string cannot carry: a glyph
    // needing a colour of its own. The battery's bolt is green while it is
    // gaining charge, next to a numeral that is on the severity ladder, and
    // one Text cannot be both.
    property Component accessory: null

    // Whether there is anything to put beside the icon. An icon-only card is
    // the expected shape, not a degenerate one, so the whole text side leaves
    // the layout when it is empty rather than sitting there as a spacing gap
    // the card still pays for.
    readonly property bool hasText: card.lineOne !== "" || card.lineTwo !== "" || card.accessory !== null

    implicitWidth: card.vertical ? Style.barCardWidth : body.implicitWidth
    implicitHeight: body.implicitHeight

    RowLayout {
        id: body

        // Left-anchored rather than centred: cards align to each other on
        // their rail, and a card centred on its own content would put every
        // rail at a different x.
        anchors.left: parent.left
        anchors.right: card.vertical ? parent.right : undefined
        anchors.verticalCenter: parent.verticalCenter
        spacing: card.vertical ? Style.barCardGap : Style.space(1.5)

        Item {
            id: rail

            Layout.preferredWidth: card.vertical ? Style.barCardRail : rail.childrenRect.width
            Layout.preferredHeight: card.vertical ? Style.barCardRail : rail.childrenRect.height
            Layout.alignment: Qt.AlignVCenter
            // Reserved on a side bar even when empty -- see the header. On a
            // top bar there is no column to align to, so an iconless card
            // gives the width back instead.
            visible: card.vertical || rail.children.length > 0
        }

        GridLayout {
            id: lines

            // One column stacks the lines, two sets them side by side. A
            // layout cannot change its base type at runtime; a grid can change
            // its count, which is the same thing said differently.
            columns: card.vertical ? 1 : 2
            rowSpacing: 0
            columnSpacing: Style.space(2)
            // Reserved on a side bar whether or not it holds anything, so the
            // card keeps one width; dropped on a top bar, where a widget is
            // only as wide as it has something to show.
            visible: card.vertical || card.hasText
            Layout.fillWidth: card.vertical
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: Style.space(1)
                // An empty line is not a blank line: an invisible child leaves
                // the layout entirely, so a card with only line two draws it
                // where line one would have been rather than below a gap.
                visible: card.lineOne !== "" || card.accessory !== null
                Layout.fillWidth: card.vertical
                Layout.alignment: Qt.AlignVCenter

                Text {
                    visible: card.lineOne !== ""
                    text: card.lineOne
                    color: card.lineOneColor
                    font.family: Style.fontFamily
                    font.pixelSize: card.lineOneSize
                    // The ceiling, enforced. A line too long for the card is
                    // cut rather than allowed to widen the bar, because the
                    // bar's width is shared with every other card in it.
                    elide: Text.ElideRight
                    Layout.maximumWidth: card.vertical ? Style.barCardText : -1
                    Layout.alignment: Qt.AlignVCenter
                }

                Loader {
                    active: card.accessory !== null
                    sourceComponent: card.accessory
                    Layout.alignment: Qt.AlignVCenter
                }

                // Holds the line against the rail. Without it the row centres
                // in the text column and the card's two lines start at
                // different x from each other. There is no column to hold it
                // against on a top bar, where it would only add its own
                // spacing to the widget's width.
                Item {
                    visible: card.vertical
                    Layout.fillWidth: card.vertical
                }
            }

            Text {
                visible: card.lineTwo !== ""
                text: card.lineTwo
                color: card.lineTwoColor
                font.family: Style.fontFamily
                font.pixelSize: card.lineTwoSize
                elide: Text.ElideRight
                Layout.maximumWidth: card.vertical ? Style.barCardText : -1
                Layout.fillWidth: card.vertical
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
