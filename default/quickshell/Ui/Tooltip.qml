// Hover detail for a bar widget.
//
// The rule from docs/quickshell-widgets.md: hover may add detail, it may not
// carry the answer. Everything shown here has to be redundant -- the thing you
// occasionally want a precise figure for, never the state the widget exists to
// communicate. If a widget's meaning depends on its tooltip, the widget is
// broken and the tooltip is hiding it.
//
// This is a real window rather than an Item inside the bar because the bar is
// 34px tall and a tooltip has to escape it. Layer-shell surfaces clip to their
// own geometry, so there is no drawing outside the panel.
//
// It never takes focus. A tooltip that steals the keyboard from the window
// underneath it is a bug in a keyboard-driven desktop, not a nicety.
//
// The shape is a speech bubble: a tail on the edge facing the bar, pointing at
// the widget that opened it. The tail tracks the widget rather than sitting at
// the bubble's middle, and that is the whole difficulty. A bubble too tall for
// the room below its widget is slid back onto the screen by the adjustment
// below -- the Clock's calendar, at the bottom of a side bar, always is -- and
// a tail fixed to the middle would then point at nothing. itemRect() gives the
// widget's bounds in this window's own coordinates once it has been placed, so
// the offset is read from where the bubble actually ended up rather than
// predicted from where it was asked to go.
//
// The tail is a square rotated 45 degrees: it protrudes half its diagonal, so
// two of its edges stand outside the body carrying the border and the other
// two are hidden under the body's own fill. What that leaves is the body's
// border running across the tail's base, which the sliver below covers.

import QtQuick
import Quickshell
import qs.Commons

PopupWindow {
    id: root

    // The widget this hangs beside.
    property Item anchorItem: null
    // Hover state, driven by the widget's own MouseArea.
    property bool open: false
    // Primary line, then a quieter second line.
    property string text: ""
    property string detail: ""

    // Long enough that sweeping the pointer across the bar on the way
    // somewhere else does not strobe every tooltip it passes over.
    property int delay: 400

    readonly property bool hasContent: text !== "" || detail !== ""
    // Set once the pointer has stayed put for `delay`. Reset the instant hover
    // ends, so leaving and returning restarts the wait rather than reopening
    // immediately.
    property bool settled: false

    // A tooltip opens away from the bar, so which way that is depends on the
    // edge the bar is on. Read off the widget being anchored to rather than
    // passed in by every caller: a bar widget already knows, and a tooltip on
    // something else keeps the top bar's downwards default.
    readonly property string barPosition: root.anchorItem && "barPosition" in root.anchorItem ? root.anchorItem.barPosition : "top"
    readonly property int openEdge: barPosition === "right" ? Edges.Left : barPosition === "left" ? Edges.Right : Edges.Bottom

    // Whether the tail sits on a horizontal edge, pointing up at a top bar, or
    // on a vertical one pointing sideways at a side bar.
    readonly property bool tailOnTop: root.openEdge === Edges.Bottom

    // How far clear of the *bar* the tail's tip stops -- not clear of the
    // widget. On a side bar the card is inset from the bar's inner edge by
    // barSidePadding, so clearance measured from the card spends most of
    // itself crossing that inset. A top-bar widget fills the bar's whole
    // thickness, so there is no inset to add back and both edges end up with
    // the same clearance.
    //
    // Reserved as empty window rather than asked for as an anchor margin.
    // PopupAnchor.margins applies to the anchor *rect*, and asking for the gap
    // that way left the tail flush against the bar: whatever the margin
    // reshapes, it is not the distance the popup is placed at. A transparent
    // strip the tail does not reach into is clearance that can be measured.
    readonly property int barClearance: Style.space(1.5)
    readonly property int standoff: root.barClearance + (root.tailOnTop ? 0 : Style.barSidePadding)
    // The whole strip between the body and the window edge facing the bar.
    readonly property int tailStrip: root.tailSize + root.standoff

    // How far the tail stands out from the body, and the square that draws it.
    // A square rotated 45 degrees protrudes half its diagonal, so the side is
    // the protrusion times root two and the base it shows is the diagonal.
    // Sized to read at a glance against a 34px card: a smaller tail was there
    // first and disappeared into the bubble's own corner radius.
    readonly property int tailSize: Style.space(2)
    readonly property int tailSquare: Math.round(root.tailSize * Math.SQRT2)
    readonly property int tailSpan: Math.round(root.tailSquare * Math.SQRT2)

    // The widget's bounds in this window's own coordinates. itemRect() is a
    // method, so the binding has to name the values whose change should send it
    // round again -- the window is measured and placed after it opens, and the
    // answer before that is not worth having.
    readonly property rect anchorRect: {
        var placed = root.visible && root.width > 0 && root.height > 0;
        if (!placed || root.anchorItem === null)
            return Qt.rect(0, 0, 0, 0);
        return root.itemRect(root.anchorItem);
    }

    // Where the tail meets the body, along the edge it sits on: the widget's
    // centre, held off the rounded corners so the bubble's outline stays whole.
    readonly property real tailPos: {
        var target = root.tailOnTop ? root.anchorRect.x + root.anchorRect.width / 2 : root.anchorRect.y + root.anchorRect.height / 2;
        var length = root.tailOnTop ? body.width : body.height;
        var lo = Style.radius + root.tailSpan / 2;
        var hi = length - Style.radius - root.tailSpan / 2;
        if (hi < lo)
            return length / 2;
        return Math.max(lo, Math.min(hi, target));
    }

    anchor {
        item: root.anchorItem
        edges: root.openEdge
        gravity: root.openEdge
        // Bar widgets sit at the screen edges, where a tooltip centred on the
        // widget would hang off the display. Slide it back inside instead of
        // letting the compositor clip it -- along the bar, whichever way that
        // runs. The tail follows, per anchorRect above.
        adjustment: root.openEdge === Edges.Bottom ? PopupAdjustment.SlideX : PopupAdjustment.SlideY
    }

    // The window holds the body, the strip the tail stands in, and the
    // clearance beyond it.
    implicitWidth: body.implicitWidth + (root.tailOnTop ? 0 : root.tailStrip)
    implicitHeight: body.implicitHeight + (root.tailOnTop ? root.tailStrip : 0)
    color: "transparent"
    grabFocus: false
    visible: root.open && root.settled && root.hasContent

    onOpenChanged: {
        if (root.open) {
            wait.restart();
        } else {
            wait.stop();
            root.settled = false;
        }
    }

    Timer {
        id: wait
        interval: root.delay
        onTriggered: root.settled = true
    }

    // Declared before the body so the body's fill paints over its inner half.
    Rectangle {
        id: tail

        width: root.tailSquare
        height: root.tailSquare
        rotation: 45
        color: body.color
        border.width: Style.borderWidth
        border.color: body.border.color

        x: (root.tailOnTop ? root.tailPos : (root.openEdge === Edges.Right ? body.x : body.x + body.width)) - width / 2
        y: (root.tailOnTop ? body.y : root.tailPos) - height / 2
    }

    Rectangle {
        id: body

        implicitWidth: column.implicitWidth + Style.space(3) * 2
        implicitHeight: column.implicitHeight + Style.space(2) * 2

        // Offset into the window by the tail's strip and the clearance beyond
        // it, on the side facing the bar.
        x: root.openEdge === Edges.Right ? root.tailStrip : 0
        y: root.tailOnTop ? root.tailStrip : 0
        width: root.width - (root.tailOnTop ? 0 : root.tailStrip)
        height: root.height - (root.tailOnTop ? root.tailStrip : 0)

        radius: Style.radius
        color: Theme.surface
        border.width: Style.borderWidth
        border.color: Theme.border

        Column {
            id: column

            anchors.centerIn: parent
            spacing: Style.space(0.5)

            Text {
                text: root.text
                visible: text !== ""
                color: Theme.barText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
            }

            Text {
                text: root.detail
                visible: text !== ""
                color: Theme.barTextMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
            }
        }
    }

    // The body's border crosses the tail's base. This covers that one segment
    // in the fill colour, so the outline reads as one shape rather than a
    // bubble with a line drawn through where the tail joins it.
    Rectangle {
        id: seam

        color: body.color
        width: root.tailOnTop ? root.tailSpan - Style.borderWidth * 2 : Style.borderWidth
        height: root.tailOnTop ? Style.borderWidth : root.tailSpan - Style.borderWidth * 2
        x: root.tailOnTop ? root.tailPos - width / 2 : (root.openEdge === Edges.Right ? body.x : body.x + body.width - Style.borderWidth)
        y: root.tailOnTop ? body.y : root.tailPos - height / 2
    }
}
