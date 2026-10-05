// The application installer: find an app, see what it is, install or remove it
// -- and, across the top, the two actions that act on everything: updating
// handaan itself, and installing every app.
//
// A view onto qs.Commons.AppCatalog and nothing more. It holds no opinion
// about what an app is, when one counts as installed, or how one is installed
// or removed -- those answers come from handaan-apps-manifest through the
// catalogue, and the work from handaan-apps-install and handaan-apps-uninstall,
// so the terminal and this window can never disagree about them.
//
// It lives in the shell rather than in a config of its own so it inherits the
// palette: every colour here is a Theme role, and regenerating or swapping the
// palette moves this window with the bar.
//
// One surface, not one per monitor: there is a single installer and it belongs
// on the monitor being looked at. That is the opposite of a bar widget, which
// is built per screen and must read its own injected BarWidget.screen.
//
// Three parts. The header says what the machine is waiting on -- updates as the
// bar's Updates indicator counts them, apps not yet installed -- and carries the
// two actions that answer it. Update is here rather than on that indicator
// because a click on the bar has to be harmless if it was a mistake (see
// modules/Updates.qml). Below it, the list on the left is a launcher: type to
// narrow, arrows to move. The pane on the right is the app under the cursor --
// what it declares, and so what an install or an uninstall would touch -- with
// its actions.
//
// Enter on an app installs, and only ever installs. Uninstall is Ctrl+Delete,
// a key of its own. Uninstall and both header actions ask twice: the first
// press arms, and the window says what will happen; the second runs it. One
// Enter too many on an app costs an idempotent reinstall; it must never cost
// the app, and an update or a full install must never happen by reflex.
// Anything else disarms.
//
// The header is reached with Tab, so the keyboard flow for apps never changes:
// the search field keeps the keyboard throughout, and Tab only moves where
// Enter and the arrows go.

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
    // One row per app: { name, summary, installed, packages, hooks, config,
    // search }.
    property var rows: []
    property int cursor: 0

    readonly property var current: root.cursor >= 0 && root.cursor < root.rows.length ? root.rows[root.cursor] : null
    readonly property bool canUninstall: root.current !== null && root.current.installed

    // "", "update", "all" or "uninstall": which two-step action the first press
    // armed. Held here rather than on a row or a button so that anything that
    // rebuilds them -- retyping the query, a fresh catalogue -- cannot leave a
    // stale armed state behind.
    property string armed: ""

    // ---------------------------------------------------------------- header
    //
    // Whether Enter and the arrows go to the header's buttons rather than the
    // list. The search field keeps the keyboard either way; this only routes
    // keys, so typing anything returns to the list without losing a keystroke.
    property bool headerFocus: false
    property int headerIndex: 0

    // Install all: the pending apps when there are any, else every installed
    // one.
    readonly property bool allPending: AppCatalog.pendingCount > 0
    readonly property var allNames: root.allPending ? AppCatalog.pendingNames : AppCatalog.installedNames
    readonly property var headerActions: root.allNames.length > 0 ? ["update", "all"] : ["update"]

    readonly property string statusText: {
        var parts = [];
        if (!Maintenance.polled)
            parts.push("Checking for updates…");
        else if (Maintenance.updates > 0)
            parts.push(Maintenance.updates + (Maintenance.updates === 1 ? " update" : " updates")
                + (Maintenance.archSecurity > 0 ? " (" + Maintenance.archSecurity + " security)" : ""));
        else
            parts.push("Up to date");

        if (AppCatalog.pendingCount > 0)
            parts.push(AppCatalog.pendingCount + (AppCatalog.pendingCount === 1 ? " app" : " apps") + " pending");
        else if (AppCatalog.entries.length > 0)
            parts.push("every app installed");
        return parts.join(" · ");
    }

    // What the second press will do, said where the status was.
    readonly property string confirmText: {
        if (root.armed === "update")
            return "Press again to update: a snapshot first, then handaan, every package, migrations and each app's update.sh. sudo asks in the terminal.";
        if (root.armed === "all")
            return "Press again to " + (root.allPending ? "install " : "reinstall ") + root.allNames.join(", ")
                + ". A full system upgrade runs first.";
        return "";
    }

    function matches(entry, query) {
        if (query.length === 0)
            return true;
        return entry.search.indexOf(query) !== -1;
    }

    function rebuildRows() {
        const query = search.text.toLowerCase().trim();
        var next = [];

        const entries = AppCatalog.entries;
        for (var i = 0; i < entries.length; i++) {
            const entry = entries[i];
            const summary = entry.summary || "";
            const row = {
                name: entry.name,
                summary: summary,
                installed: entry.installed === true,
                packages: entry.packages || [],
                hooks: entry.hooks || [],
                config: entry.config || [],
                search: (entry.name + " " + summary).toLowerCase()
            };
            if (root.matches(row, query))
                next.push(row);
        }

        root.rows = next;
        root.armed = "";
        root.cursor = next.length > 0 ? 0 : -1;
    }

    function select(index) {
        root.headerFocus = false;
        if (index === root.cursor)
            return;
        root.armed = "";
        root.cursor = index;
        list.positionViewAtIndex(root.cursor, ListView.Contain);
    }

    function moveCursor(delta) {
        if (root.rows.length === 0)
            return;
        // Wraps, because a short list is faster to leave by the near end than
        // to walk back through.
        root.select((root.cursor + delta + root.rows.length) % root.rows.length);
    }

    // Enter on an app, and the pane's primary button.
    function activate() {
        const row = root.current;
        if (!row)
            return;

        // Enter never confirms an uninstall. An armed uninstall met by Enter
        // is a change of mind, not a second press.
        if (root.armed !== "") {
            root.armed = "";
            return;
        }

        AppCatalog.install([row.name]);
        AppCatalog.close();
    }

    // Ctrl+Delete, and the pane's Uninstall button.
    function uninstall() {
        if (!root.canUninstall)
            return;
        root.headerFocus = false;
        if (root.armed !== "uninstall") {
            root.armed = "uninstall";
            return;
        }
        AppCatalog.uninstall([root.current.name]);
        AppCatalog.close();
    }

    // A header button, by keyboard or pointer: the first press arms, the
    // second runs.
    function runHeader(action) {
        root.headerFocus = true;
        root.headerIndex = Math.max(0, root.headerActions.indexOf(action));
        if (root.armed !== action) {
            root.armed = action;
            return;
        }
        if (action === "update")
            AppCatalog.update();
        else
            AppCatalog.install(root.allNames);
        AppCatalog.close();
    }

    function moveHeader(delta) {
        const count = root.headerActions.length;
        root.armed = "";
        root.headerIndex = (root.headerIndex + delta + count) % count;
    }

    function toggleHeaderFocus() {
        root.armed = "";
        root.headerFocus = !root.headerFocus;
        root.headerIndex = 0;
    }

    function dismiss() {
        if (root.armed !== "") {
            root.armed = "";
            return;
        }
        if (root.headerFocus) {
            root.headerFocus = false;
            return;
        }
        AppCatalog.close();
    }

    // Every key, in one place, because where it goes depends on headerFocus.
    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;

        switch (event.key) {
        case Qt.Key_Tab:
        case Qt.Key_Backtab:
            root.toggleHeaderFocus();
            return;
        case Qt.Key_Escape:
            root.dismiss();
            return;
        case Qt.Key_Up:
            if (root.headerFocus)
                root.toggleHeaderFocus();
            else
                root.moveCursor(-1);
            return;
        case Qt.Key_Down:
            if (root.headerFocus)
                root.toggleHeaderFocus();
            else
                root.moveCursor(1);
            return;
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (root.headerFocus) {
                root.moveHeader(event.key === Qt.Key_Left ? -1 : 1);
                return;
            }
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (root.headerFocus)
                root.runHeader(root.headerActions[root.headerIndex]);
            else
                root.activate();
            return;
        case Qt.Key_Delete:
            // Taken before the field sees it, which would otherwise delete the
            // word after the caret. Plain Delete stays the field's.
            if (ctrl) {
                root.uninstall();
                return;
            }
            break;
        default:
            // Typing goes back to the list, and still types.
            if (root.headerFocus && event.text.length > 0) {
                root.headerFocus = false;
                root.armed = "";
            }
            break;
        }
        event.accepted = false;
    }

    function hookList(hooks) {
        if (hooks.length === 0)
            return "none";
        var names = [];
        for (var i = 0; i < hooks.length; i++)
            names.push(hooks[i] + ".sh");
        return names.join(" · ");
    }

    // Rebuilt from the catalogue every time the window opens, so a row can
    // never claim a state that an install or uninstall since has changed.
    onVisibleChanged: {
        if (visible) {
            search.text = "";
            root.headerFocus = false;
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
    // nothing runs until an action is chosen, and every expensive one asks
    // twice.
    MouseArea {
        anchors.fill: parent
        onClicked: AppCatalog.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barBackground
        opacity: 0.55
    }

    // A button. The key beside the label is the same action from the keyboard,
    // so the window teaches the keys rather than replacing them. `focused` is
    // the header's keyboard cursor, drawn as a heavier border.
    component PaneButton: Rectangle {
        id: button

        property string label
        property string key
        property color tone: Theme.active
        property bool filled: false
        property bool focused: false

        signal activated

        implicitWidth: buttonRow.implicitWidth + Style.space(5)
        implicitHeight: buttonRow.implicitHeight + Style.space(2.5)
        radius: Style.radius
        color: button.filled ? button.tone : (buttonMouse.containsMouse || button.focused ? Theme.surfaceHover : "transparent")
        border.width: button.focused ? 2 : Style.borderWidth
        border.color: button.tone

        RowLayout {
            id: buttonRow

            anchors.centerIn: parent
            spacing: Style.space(2)

            Text {
                text: button.label
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.bold: true
                color: button.filled ? Theme.barBackground : button.tone
            }

            Text {
                visible: button.key.length > 0
                text: button.key
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: button.filled ? Theme.barBackground : Theme.barTextMuted
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.activated()
        }
    }

    // One "label  value" line of the pane's facts.
    component Fact: RowLayout {
        id: fact

        property string label
        property string value
        property bool muted: false

        Layout.fillWidth: true
        spacing: Style.space(3)

        Text {
            Layout.preferredWidth: Style.space(18)
            Layout.alignment: Qt.AlignTop
            text: fact.label
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Theme.barTextMuted
        }

        Text {
            Layout.fillWidth: true
            text: fact.value
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: fact.muted ? Theme.barTextMuted : Theme.barText
            wrapMode: Text.Wrap
        }
    }

    // The wallpaper picker's card; see DialogCard.
    DialogCard {
        id: card

        anchors.centerIn: parent
        width: Math.min(880, parent.width - Style.space(8))
        // A fixed height, not one that follows the content: the pane changes
        // with every cursor move, and a card resizing under the cursor would
        // move the list being read.
        height: Math.min(560, parent.height - Style.space(8))

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(4)
            spacing: Style.space(3)

            // ------------------------------------------------------ header
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(3)

                // What is waiting, or -- while a header action is armed --
                // what the second press will do. Loud only while armed.
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.confirmText.length > 0 ? root.confirmText : root.statusText
                    font.family: Style.fontFamily
                    font.pixelSize: root.confirmText.length > 0 ? Style.fontSizeSmall : Style.fontSize
                    font.bold: root.confirmText.length === 0
                    color: {
                        if (root.confirmText.length > 0)
                            return Theme.warning;
                        if (Maintenance.archSecurity > 0)
                            return Theme.critical;
                        return Theme.barText;
                    }
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                PaneButton {
                    label: root.armed === "update" ? "Confirm update" : "↻ Update"
                    key: ""
                    tone: root.armed === "update" ? Theme.warning : Theme.active
                    filled: root.armed === "update"
                    focused: root.headerFocus && root.headerActions[root.headerIndex] === "update"
                    onActivated: root.runHeader("update")
                }

                PaneButton {
                    visible: root.allNames.length > 0
                    label: {
                        if (root.armed === "all")
                            return "Confirm";
                        return (root.allPending ? "▸ Install all (" : "▸ Reinstall all (") + root.allNames.length + ")";
                    }
                    key: ""
                    tone: root.armed === "all" ? Theme.warning : Theme.active
                    filled: root.armed === "all"
                    focused: root.headerFocus && root.headerActions[root.headerIndex] === "all"
                    onActivated: root.runHeader("all")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.borderWidth
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.space(4)

                // ------------------------------------------------ list pane
                //
                // Both panes are fixed, not sized from what they hold: a layout
                // starts every item at its content's width, so a long summary
                // or package list in the pane would otherwise take width from
                // the list, and the split would move with the cursor. The list
                // gets exactly this; the pane gets the rest of the card.
                ColumnLayout {
                    Layout.minimumWidth: 300
                    Layout.preferredWidth: 300
                    Layout.maximumWidth: 300
                    Layout.fillHeight: true
                    spacing: Style.space(3)

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: search.implicitHeight + Style.space(3)
                        radius: Style.radius
                        color: Theme.surface
                        border.width: Style.borderWidth
                        border.color: search.activeFocus && !root.headerFocus ? Theme.active : Theme.border

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

                            // Arrow keys drive the list rather than the caret:
                            // a single-line field has nowhere vertical to go,
                            // so the keystroke is free and the hand never
                            // leaves the query. Everything is routed through
                            // handleKey, since where a key goes depends on
                            // whether the header has the cursor.
                            Keys.onPressed: event => root.handleKey(event)

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

                    // "Nothing offered", "the check failed" and "nothing
                    // matched" are three different answers, so they do not
                    // share a message. A catalogue that could not be read must
                    // never read as an empty one.
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

                    ListView {
                        id: list

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.rows.length > 0

                        model: root.rows
                        clip: true
                        spacing: Style.space(0.5)
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: row

                            required property int index
                            required property var modelData

                            readonly property bool isCurrent: root.cursor === row.index
                            readonly property bool isArmed: row.isCurrent && root.armed === "uninstall"

                            width: list.width
                            height: rowLayout.implicitHeight + Style.space(2.5)
                            radius: Style.radius

                            color: {
                                if (row.isArmed)
                                    return Theme.critical;
                                if (row.isCurrent)
                                    return root.headerFocus ? Theme.surface : Theme.surfaceHover;
                                return "transparent";
                            }

                            // A click selects; it does not act. The actions
                            // are in the pane, where what they touch is shown.
                            // Hover does not select either: the pointer
                            // crosses the list on its way to the pane's
                            // buttons, and must not change what they act on.
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.select(row.index)
                                onDoubleClicked: root.activate()
                            }

                            RowLayout {
                                id: rowLayout

                                anchors.fill: parent
                                anchors.leftMargin: Style.space(2)
                                anchors.rightMargin: Style.space(3)
                                spacing: Style.space(2)

                                // Where the app stands, at a glance: filled
                                // for installed, nothing for not.
                                Text {
                                    Layout.preferredWidth: Style.space(3)
                                    horizontalAlignment: Text.AlignHCenter
                                    text: row.modelData.installed ? "●" : ""
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeSmall
                                    color: {
                                        if (row.isArmed)
                                            return Theme.barBackground;
                                        return row.modelData.installed ? Theme.good : Theme.barTextMuted;
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSize
                                    font.bold: row.isCurrent
                                    color: row.isArmed ? Theme.barBackground : Theme.barText
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Style.borderWidth
                    color: Theme.border
                }

                // ------------------------------------------------ detail pane
                ColumnLayout {
                    id: pane

                    readonly property var row: root.current

                    // Zero, so the pane's width is only the space left over and
                    // never what its text would like; see the list pane.
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.space(3)
                    visible: pane.row !== null

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(3)

                        Text {
                            Layout.fillWidth: true
                            text: pane.row ? pane.row.name : ""
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize + 4
                            font.bold: true
                            color: Theme.barText
                            elide: Text.ElideRight
                        }

                        Text {
                            text: !pane.row ? "" : (pane.row.installed ? "installed" : "not installed")
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: pane.row && pane.row.installed ? Theme.good : Theme.barTextMuted
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: pane.row ? pane.row.summary : ""
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize
                        color: Theme.barTextMuted
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    // What the app declares, which is exactly what an install
                    // brings and an uninstall judges. Read from the manifest,
                    // so it is the app directory as it stands.
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(1.5)

                        Fact {
                            label: "Packages"
                            value: pane.row && pane.row.packages.length > 0 ? pane.row.packages.join(", ") : "none declared"
                            muted: !pane.row || pane.row.packages.length === 0
                        }

                        Fact {
                            label: "Hooks"
                            value: pane.row ? root.hookList(pane.row.hooks) : ""
                            muted: !pane.row || pane.row.hooks.length === 0
                        }

                        Fact {
                            label: "Config"
                            value: {
                                if (!pane.row || pane.row.config.length === 0)
                                    return "none";
                                const shown = pane.row.config.slice(0, 5);
                                const more = pane.row.config.length - shown.length;
                                return shown.join("\n") + (more > 0 ? "\n+" + more + " more" : "");
                            }
                            muted: !pane.row || pane.row.config.length === 0
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // The second Ctrl+Delete, spelled out. Loud on purpose: the
                    // one thing on the card that should be read before a key is.
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.armed === "uninstall"
                        implicitHeight: armedText.implicitHeight + Style.space(4)
                        radius: Style.radius
                        color: Theme.critical

                        Text {
                            id: armedText

                            anchors.fill: parent
                            anchors.margins: Style.space(2)
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: Theme.barBackground
                            wrapMode: Text.WordWrap
                            text: {
                                const row = pane.row;
                                if (!row || root.armed !== "uninstall")
                                    return "";
                                var lines = ["Press Ctrl+Delete again to uninstall " + row.name + "."];
                                lines.push(row.hooks.indexOf("uninstall") !== -1
                                    ? "· uninstall.sh runs first."
                                    : "· No uninstall.sh: whatever install.sh did stays.");
                                if (row.config.length > 0)
                                    lines.push("· Its " + row.config.length + " config file(s) are removed; edited ones are kept in retired-config.");
                                if (row.packages.length > 0)
                                    lines.push("· " + row.packages.join(", ") + " released, unless another app or handaan's core declares them.");
                                return lines.join("\n");
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(2)

                        PaneButton {
                            label: pane.row && pane.row.installed ? "Reinstall" : "Install"
                            key: "Enter"
                            onActivated: {
                                root.headerFocus = false;
                                root.activate();
                            }
                        }

                        PaneButton {
                            visible: root.canUninstall
                            label: root.armed === "uninstall" ? "Confirm uninstall" : "Uninstall"
                            key: "Ctrl+Del"
                            tone: Theme.critical
                            filled: root.armed === "uninstall"
                            onActivated: root.uninstall()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // -------------------------------------------------------- footer
            Text {
                Layout.fillWidth: true
                text: {
                    if (root.armed !== "")
                        return "Esc cancel";
                    if (root.headerFocus)
                        return "←→ choose · Enter arm, Enter again to run · Tab back to apps · Esc back";
                    return "↑↓ move · Enter install · Ctrl+Del uninstall · Tab update / install all · Esc close";
                }
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Theme.barTextMuted
            }
        }
    }
}
