// The bar host: one layer-shell surface per monitor, three content sections.
//
// Sections are supplied as Components rather than Items because Variants
// instantiates this whole surface once per screen, and each screen needs its
// own copy of every widget. A shared Item would be reparented onto whichever
// screen mapped last, leaving the others blank.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

Item {
    id: root

    // Widget components, in display order, per section.
    property list<Component> leftWidgets
    property list<Component> centerWidgets
    property list<Component> rightWidgets

    property string position: "top"
    property bool hidden: false

    readonly property int barSize: Style.barSize
    readonly property color background: Theme.barSurface
    readonly property color foreground: Theme.barText

    // Run a command without keeping a child process attached to the shell.
    // execDetached double-forks, so a spawned terminal outliving the shell
    // cannot take the bar down with it.
    function run(command) {
        Quickshell.execDetached(["sh", "-c", command]);
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarSurface {
                required property var modelData

                screen: modelData
            }
        }
    }

    component BarSurface: PanelWindow {
        id: surface

        // Which way the bar runs. A side bar spans the screen's height and
        // takes its thickness from implicitWidth; a top or bottom one is the
        // other way round. Everything below that differs between the two reads
        // this rather than testing position again.
        readonly property bool vertical: root.position === "left" || root.position === "right"

        // Hiding parks the surface just past the screen edge instead of
        // unmapping it. Unmapping frees the layer surface and the entire scene
        // graph, so every reveal has to rebuild both; a negative margin leaves
        // everything mapped and costs one property change.
        // The window is not always the bar. When the island expands it grows
        // downward past the bar's own thickness, so the reserved strip has to
        // be stated rather than taken from the window's size -- otherwise
        // every window on the screen would move each time the island opened.
        // Auto is kept on a side bar, which never grows.
        exclusionMode: root.hidden ? ExclusionMode.Ignore : (surface.vertical ? ExclusionMode.Auto : ExclusionMode.Normal)
        exclusiveZone: root.barSize

        margins {
            top: root.hidden && root.position === "top" ? -root.barSize : 0
            bottom: root.hidden && root.position === "bottom" ? -root.barSize : 0
            left: root.hidden && root.position === "left" ? -root.barSize : 0
            right: root.hidden && root.position === "right" ? -root.barSize : 0
        }

        // Anchored to both ends of the axis it spans, and to the edge it sits
        // on. The layer surface takes its length from those two anchors, so
        // only the thickness is given below.
        anchors {
            top: surface.vertical || root.position === "top"
            bottom: surface.vertical || root.position === "bottom"
            left: !surface.vertical || root.position === "left"
            right: !surface.vertical || root.position === "right"
        }

        // A top bar's thickness is barSize, the height a row of widgets needs.
        // A side bar's is Style.barSideSize, the width budget its widgets are
        // sized from. The content is still measured, as a floor: a widget that
        // cannot shrink to the budget widens the bar rather than being
        // clipped by it.
        readonly property int contentThickness: Math.max(leftRow.implicitWidth, centerRow.implicitWidth, rightRow.implicitWidth)

        implicitWidth: surface.vertical ? Math.max(Style.barSideSize, surface.contentThickness + Style.barSidePadding * 2) : 0
        implicitHeight: surface.vertical ? 0 : root.barSize + island.overflow
        color: root.background
        // The centre section. A sibling of the strip rather than a child of
        // it, because it starts inside the bar and ends below it, and pinned
        // to the top for the same reason the rows are.
        Island {
            id: island

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            vertical: surface.vertical
        }

        // The compositor handles clicks outside this window, including on
        // another monitor. The bar itself is also in the grab, so observe
        // its clicks separately without stealing the widgets' actions.
        HyprlandFocusGrab {
            windows: [surface]
            active: island.expanded && !root.hidden && !surface.vertical
            onCleared: island.expanded = false
        }

        TapHandler {
            acceptedButtons: Qt.AllButtons
            onTapped: {
                const position = island.hitArea.mapFromItem(parent, point.position);
                if (!island.hitArea.contains(position))
                    island.expanded = false;
            }
        }

        Connections {
            target: root
            function onHiddenChanged() {
                if (root.hidden)
                    island.expanded = false;
            }
        }

        // Only the bar and the island take the pointer. The rest of the
        // window is the room the island expands into, and without this it
        // would swallow every click across the top of the screen.
        mask: Region {
            item: barArea

            Region {
                item: island.hitArea
            }
        }

        WlrLayershell.namespace: "quickshell-bar"
        WlrLayershell.layer: WlrLayer.Top

        // Sections are siblings in a single row. Center is anchored to the
        // surface rather than placed between the other two, so whatever sits
        // in it stays centred on the screen: a long window title growing on
        // the left would otherwise shove it sideways.
        //
        // On a side bar the same three sections read top, middle and bottom:
        // leftWidgets is the leading edge of the bar whichever way it runs.
        Item {
            id: barArea

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: surface.vertical ? surface.height : root.barSize
        }

        Item {
            anchors.fill: barArea
            anchors.leftMargin: surface.vertical ? Style.barSidePadding : Style.barPadding
            anchors.rightMargin: surface.vertical ? Style.barSidePadding : Style.barPadding
            anchors.topMargin: surface.vertical ? Style.barPadding : 0
            anchors.bottomMargin: surface.vertical ? Style.barPadding : 0

            WidgetRow {
                id: leftRow
                widgets: root.leftWidgets
                screen: surface.screen
                vertical: surface.vertical
                anchors.left: surface.vertical ? undefined : parent.left
                anchors.top: surface.vertical ? parent.top : undefined
                anchors.verticalCenter: surface.vertical ? undefined : parent.verticalCenter
                anchors.horizontalCenter: surface.vertical ? parent.horizontalCenter : undefined
            }

            // The bar's centre section. Not a WidgetRow: the island is not
            // built from widgets and does not take a list of them -- see
            // docs/island/README.md. Centred on both axes, like centerRow below.
            // Centred on both axes either way, so this one needs no case.
            WidgetRow {
                id: centerRow
                widgets: root.centerWidgets
                screen: surface.screen
                vertical: surface.vertical
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            WidgetRow {
                id: rightRow
                widgets: root.rightWidgets
                screen: surface.screen
                vertical: surface.vertical
                anchors.right: surface.vertical ? undefined : parent.right
                anchors.bottom: surface.vertical ? parent.bottom : undefined
                anchors.verticalCenter: surface.vertical ? undefined : parent.verticalCenter
                anchors.horizontalCenter: surface.vertical ? parent.horizontalCenter : undefined
            }
        }
    }

    // A GridLayout rather than a RowLayout because the section has to run
    // either way: one row on a top bar, one column on a side one. A layout
    // cannot change its base type at runtime, but a single-row grid and a
    // single-column grid are the same type with different counts.
    component WidgetRow: GridLayout {
        id: row

        property list<Component> widgets
        // Forwarded to every widget in the row. See BarWidget.screen.
        property var screen: null
        property bool vertical: false

        // Counted from the declared widgets rather than the loaded ones: a
        // widget that reports itself inactive is dropped by the layout, and
        // the spare cell it leaves behind costs nothing.
        columns: row.vertical ? 1 : row.widgets.length
        rows: row.vertical ? row.widgets.length : 1

        rowSpacing: Style.widgetSpacing
        columnSpacing: Style.widgetSpacing
        height: row.vertical ? implicitHeight : root.barSize
        width: implicitWidth

        Repeater {
            model: row.widgets

            delegate: Loader {
                required property Component modelData

                sourceComponent: modelData
                Layout.alignment: row.vertical ? Qt.AlignHCenter : Qt.AlignVCenter

                // A widget that reports itself inactive leaves the row. This
                // reads BarWidget.active rather than the item's own visible,
                // because setting a Loader invisible propagates down and would
                // drive item.visible false, latching the widget off for good.
                visible: item && "active" in item ? item.active : true

                // The widget is constructed before these assignments land, so
                // BarWidget's geometry properties fall back to Style until the
                // host is attached. See BarWidget.qml.
                onLoaded: {
                    if (item && "bar" in item)
                        item.bar = root;
                    if (item && "screen" in item)
                        item.screen = row.screen;
                }
            }
        }
    }
}
