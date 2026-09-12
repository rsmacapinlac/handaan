// The application installer: find an app, install it.
//
// A view onto qs.Commons.AppCatalog and nothing more. It holds no opinion
// about what an app is, when one counts as installed, or how one is installed
// -- those answers come from handaan-apps-manifest through the catalogue, so
// the terminal and this window can never disagree about them.
//
// It lives in the shell rather than in a config of its own so it inherits the
// palette: every colour here is a Theme role, and regenerating or swapping the
// palette moves this window with the bar. The standalone version it replaced
// could not do that -- a separate Quickshell config cannot reach qs.Commons,
// so it carried its own hardcoded copy of Mocha that silently drifted.
//
// One surface, not one per monitor: there is a single installer and it belongs
// on the monitor being looked at. That is the opposite of a bar widget, which
// is built per screen and must read its own injected BarWidget.screen.
//
// The interaction is a launcher, not a form. You type to narrow, move with the
// arrows, and Enter installs the one app under the cursor -- there is no
// multi-select and no Install button to travel to. Installing one app is the
// overwhelmingly common case, and a checkbox list made it the slowest one:
// tick, then cross the dialog, then confirm. It also made the tick ambiguous,
// since an already-installed app started ticked and unticking it did nothing.
// A single row that acts when chosen has no such state to misread.
//
// Install all is the exception, and it is the only thing here that asks twice.
// It is a deliberate break from "no confirmations" because it is the one
// action whose cost is not visible from the row: a full system upgrade plus
// every pending app, which on a fresh machine is an hour. One Enter too many
// on a single app costs an idempotent reinstall; one on this costs the
// afternoon.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: root

    // Unmapped when closed, unlike the bar, which parks itself off-screen to
    // avoid rebuilding its scene graph. A dialog is opened rarely and holds
    // exclusive keyboard focus while it is up, so keeping the surface mapped
    // would cost the session its keyboard for a window nobody is looking at.
    visible: AppCatalog.installerOpen

    // HyprlandMonitor carries no handle to a ShellScreen, so the focused
    // monitor is matched by connector name -- both sides call it "eDP-1".
    // Hyprland.focusedMonitor is session-wide, which is wrong for a bar widget
    // and exactly right here: there is one installer and one focused monitor.
    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor;
        if (!monitor)
            return null;
        const screens = Quickshell.screens;
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === monitor.name)
                return screens[i];
        }
        return null;
    }

    screen: root.focusedScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "handaan-installer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ------------------------------------------------------------------ rows
    //
    // The list is rows to act on, not apps: the install-all row sits in it
    // rather than beside it, so one cursor reaches everything and the keyboard
    // never has to leave the list to find an action. Each row is
    // { kind, name, summary, installed, search }.
    property var rows: []
    property int cursor: 0

    // Armed by the first Enter on the install-all row, cleared by anything
    // else. Held here rather than on the row so that retyping the query, which
    // rebuilds every row, cannot leave a stale armed state behind.
    property bool confirmingAll: false

    readonly property int pendingCount: AppCatalog.pendingCount

    // Set by the first real pointer movement over the dialog. See the row's
    // MouseArea for why a dialog that opens under the pointer needs it.
    property bool pointerArmed: false

    function matches(entry, query) {
        if (query.length === 0)
            return true;
        return entry.search.indexOf(query) !== -1;
    }

    function rebuildRows() {
        const query = search.text.toLowerCase().trim();
        var next = [];

        // Offered only when it would do something. An install-all row on a
        // machine with nothing pending is a row that answers no question, and
        // the one place a stray Enter is expensive.
        if (root.pendingCount > 0) {
            next.push({
                kind: "all",
                name: "Install all pending",
                summary: root.pendingCount + (root.pendingCount === 1 ? " app" : " apps") + " not installed yet",
                installed: false,
                search: "install all pending"
            });
        }

        const entries = AppCatalog.entries;
        for (var i = 0; i < entries.length; i++) {
            const entry = entries[i];
            const summary = entry.summary || "";
            next.push({
                kind: "app",
                name: entry.name,
                summary: summary,
                installed: entry.installed === true,
                search: (entry.name + " " + summary).toLowerCase()
            });
        }

        var filtered = [];
        for (var j = 0; j < next.length; j++) {
            if (root.matches(next[j], query))
                filtered.push(next[j]);
        }

        root.rows = filtered;
        root.confirmingAll = false;
        root.cursor = filtered.length > 0 ? 0 : -1;
    }

    function moveCursor(delta) {
        if (root.rows.length === 0)
            return;
        root.confirmingAll = false;
        // Wraps, because a list this short is faster to leave by the near end
        // than to walk back through.
        root.cursor = (root.cursor + delta + root.rows.length) % root.rows.length;
        list.positionViewAtIndex(root.cursor, ListView.Contain);
    }

    function activate() {
        if (root.cursor < 0 || root.cursor >= root.rows.length)
            return;
        const row = root.rows[root.cursor];

        if (row.kind === "all") {
            if (!root.confirmingAll) {
                root.confirmingAll = true;
                return;
            }
            var pending = [];
            const entries = AppCatalog.entries;
            for (var i = 0; i < entries.length; i++) {
                if (!entries[i].installed)
                    pending.push(entries[i].name);
            }
            AppCatalog.install(pending);
            AppCatalog.close();
            return;
        }

        AppCatalog.install([row.name]);
        AppCatalog.close();
    }

    function dismiss() {
        if (root.confirmingAll) {
            root.confirmingAll = false;
            return;
        }
        AppCatalog.close();
    }

    // Rebuilt from the catalogue every time the window opens, so a row can
    // never claim an installed state that an install since has changed.
    onVisibleChanged: {
        if (visible) {
            search.text = "";
            root.pointerArmed = false;
            root.rebuildRows();
            search.forceActiveFocus();
        }
    }

    Connections {
        target: AppCatalog
        function onEntriesChanged() {
            if (root.visible)
                root.rebuildRows();
        }
    }

    // Click anywhere outside the card to dismiss. Closing is always safe:
    // nothing is installed until a row is chosen, and nothing is ever removed.
    MouseArea {
        anchors.fill: parent
        onClicked: AppCatalog.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barBackground
        opacity: 0.55
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(560, parent.width - Style.space(8))
        height: Math.min(implicitHeight, parent.height - Style.space(8))
        implicitHeight: layout.implicitHeight + Style.space(8)

        color: Theme.barBackground
        radius: Style.radius
        border.width: Style.borderWidth
        border.color: Theme.border

        // Swallow clicks so the dismiss handler behind the card does not fire
        // when the pointer lands on the dialog itself. hoverEnabled is what
        // arms pointer selection: see pointerArmed.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: root.pointerArmed = true
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Style.space(4)
            spacing: Style.space(3)

            // ------------------------------------------------------- search
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: search.implicitHeight + Style.space(3)
                radius: Style.radius
                color: Theme.surface
                border.width: Style.borderWidth
                border.color: search.activeFocus ? Theme.active : Theme.border

                TextInput {
                    id: search

                    anchors.fill: parent
                    anchors.leftMargin: Style.space(3)
                    anchors.rightMargin: Style.space(3)
                    verticalAlignment: TextInput.AlignVCenter

                    focus: true
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    color: Theme.barText
                    selectionColor: Theme.active
                    selectedTextColor: Theme.barBackground
                    clip: true

                    onTextChanged: root.rebuildRows()

                    // Arrow keys drive the list rather than the caret: a
                    // single-line field has nowhere vertical to go, so the
                    // keystroke is free and the hand never leaves the query.
                    Keys.onUpPressed: root.moveCursor(-1)
                    Keys.onDownPressed: root.moveCursor(1)
                    Keys.onReturnPressed: root.activate()
                    Keys.onEnterPressed: root.activate()
                    Keys.onEscapePressed: root.dismiss()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search applications"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        color: Theme.barTextMuted
                    }
                }
            }

            // ------------------------------------------------------ messages
            //
            // "Nothing offered", "the check failed" and "nothing matched" are
            // three different answers, so they do not share a message. A
            // catalogue that could not be read must never read as an empty one.
            Text {
                Layout.fillWidth: true
                visible: AppCatalog.error !== ""
                text: AppCatalog.error + "\nRun handaan-apps-manifest in a terminal to see why."
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.critical
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: AppCatalog.error === "" && AppCatalog.loaded
                         && AppCatalog.entries.length === 0
                text: "No apps found under ~/.config/handaan/apps.\nSee docs/extending-with-apps.md for how to add one."
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: AppCatalog.loaded && AppCatalog.entries.length > 0 && root.rows.length === 0
                text: "Nothing matches \"" + search.text + "\"."
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
                elide: Text.ElideRight
            }

            Text {
                visible: !AppCatalog.loaded
                text: "Reading the catalogue..."
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
            }

            // ---------------------------------------------------------- rows
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Math.min(contentHeight, 380)
                visible: root.rows.length > 0

                model: root.rows
                clip: true
                spacing: Style.space(0.5)
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row

                    required property int index
                    required property var modelData

                    readonly property bool current: root.cursor === row.index
                    readonly property bool isAll: row.modelData.kind === "all"
                    readonly property bool arming: row.isAll && root.confirmingAll

                    width: list.width
                    height: rowLayout.implicitHeight + Style.space(2)
                    radius: Style.radius

                    color: {
                        if (row.arming)
                            return Theme.warning;
                        if (row.current)
                            return Theme.surfaceHover;
                        return "transparent";
                    }

                    // A row under the pointer becomes the cursor, but only once
                    // the pointer has actually moved. The dialog opens under
                    // wherever the pointer already was, and without this guard
                    // that stale position steals the cursor from the keyboard
                    // before a key is pressed.
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: {
                            root.pointerArmed = true;
                            if (root.cursor !== row.index) {
                                root.confirmingAll = false;
                                root.cursor = row.index;
                            }
                        }
                        onEntered: {
                            if (root.pointerArmed && root.cursor !== row.index) {
                                root.confirmingAll = false;
                                root.cursor = row.index;
                            }
                        }
                        onClicked: {
                            root.cursor = row.index;
                            root.activate();
                        }
                    }

                    RowLayout {
                        id: rowLayout

                        anchors.fill: parent
                        anchors.leftMargin: Style.space(3)
                        anchors.rightMargin: Style.space(3)
                        spacing: Style.space(2)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                spacing: Style.space(1.5)

                                Text {
                                    text: row.modelData.name
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSize
                                    font.bold: row.isAll || row.current
                                    color: row.arming ? Theme.barBackground : Theme.barText
                                }

                                Text {
                                    visible: row.modelData.installed
                                    text: "installed"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                    color: Theme.good
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: row.modelData.summary.length > 0
                                text: row.arming
                                      ? "Press Enter again to confirm. This runs a full system upgrade first."
                                      : row.modelData.summary
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSizeSmall
                                color: row.arming ? Theme.barBackground : Theme.barTextMuted
                                elide: Text.ElideRight
                            }
                        }

                        // The affordance sits on the row that is about to act,
                        // rather than on a button the cursor has to travel to.
                        Text {
                            visible: row.current && !row.arming
                            text: row.isAll ? "install all" : (row.modelData.installed ? "reinstall" : "install")
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: Theme.active
                        }
                    }
                }
            }

            // -------------------------------------------------------- footer
            Text {
                Layout.fillWidth: true
                visible: root.rows.length > 0
                text: "↑↓ move · Enter install · Esc close"
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
            }
        }
    }

}
