// Desktop notifications: the server, the history, the popups, do-not-disturb.
//
// This process is the session's notification daemon. NotificationServer claims
// org.freedesktop.Notifications on the session bus, which only one program can
// own, so no other notification daemon is installed: any that ships a D-Bus
// activation file would be started by the first notification sent before the
// shell was up, and the shell would never get the name. See ADR 0008.
//
// A singleton for the reason every always-resident thing here is one: the
// popups and the history panel are views that come and go, and a notification
// has to be received whether or not either is drawn. It must be reached as
// `qs.Commons.NotificationCenter`, never by relative path. Named for what it is
// rather than `Notifications`, which is Quickshell's own module name.
//
// A notification is kept -- tracked, in the protocol's sense -- until you
// dismiss it or clear the history, not merely until its popup times out. That
// is what lets its actions still work from the history panel, and it is the
// same promise GNOME and KDE make by declaring persistence. The popup expiring
// only takes it off the screen.
//
// History lives in memory only. Nothing an app puts in a notification -- a
// message preview, a sender -- is written to disk, and a shell restart or a
// logout starts it empty. Do-not-disturb is the exception, since forgetting it
// at login would undo the one thing it is for.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // How long a popup stays when the sender does not say, and how many are on
    // screen at once. More than a handful stacked down the screen stops being a
    // notification and becomes a feed; the rest wait in history.
    readonly property int defaultTimeout: 8000
    readonly property int popupLimit: 4
    readonly property int historyLimit: 100

    // Newest first. Plain records, copied out of each Notification so a record
    // outlives the object behind it:
    //   { id, appName, appIcon, image, summary, body, urgency, time, seen, actions }
    // urgency is "low" | "normal" | "critical"; actions are { identifier, text }
    // and only invokable while the notification is still tracked.
    property var history: []

    // On screen as popups, newest first, each with when it goes away.
    //   { id, deadline, record }   deadline is 0 for one that stays until dismissed
    // The record rides along because a transient notification has none in
    // history to look up.
    property var popups: []

    property bool historyOpen: false
    property bool doNotDisturb: false

    readonly property int unseen: {
        var count = 0;
        for (var i = 0; i < root.history.length; i++) {
            if (!root.history[i].seen)
                count += 1;
        }
        return count;
    }

    // Ticks so "5m ago" moves on. Coarse on purpose: nothing here is precise to
    // the second, and a faster tick would redraw every card for nothing.
    property double now: Date.now()

    // The live Notification objects, by id. Not a binding source -- records are
    // what views draw -- just the handle an action or a dismissal needs.
    property var objects: ({})

    // Popups the pointer is resting on, and when it last left each. A popup
    // does not time out from under someone reading it, nor the instant the
    // pointer moves off one whose time ran out meanwhile. Kept out of `popups`
    // on purpose: rewriting that list rebuilds every card on screen.
    property var held: ({})
    property var released: ({})

    readonly property string statePath: (Quickshell.env("HANDAAN_STATE") || Quickshell.env("HOME") + "/.local/state/handaan") + "/notifications"

    // ----------------------------------------------------------------- lookup

    function record(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id)
                return root.history[i];
        }
        return null;
    }

    function urgencyName(value) {
        if (value === NotificationUrgency.Critical)
            return "critical";
        if (value === NotificationUrgency.Low)
            return "low";
        return "normal";
    }

    function snapshot(n) {
        var actions = [];
        for (var i = 0; i < n.actions.length; i++)
            actions.push({ identifier: n.actions[i].identifier, text: n.actions[i].text });
        return {
            id: n.id,
            appName: n.appName,
            appIcon: n.appIcon,
            image: n.image,
            summary: n.summary,
            body: n.body,
            urgency: root.urgencyName(n.urgency),
            time: Date.now(),
            seen: false,
            transient: n.transient,
            actions: actions
        };
    }

    // ---------------------------------------------------------------- receive

    function receive(n) {
        // Untracked, the server discards it the moment this handler returns.
        n.tracked = true;

        const known = root.objects[n.id] !== undefined;
        root.objects[n.id] = n;

        if (!known) {
            // An app replacing its own notification (a download's progress, a
            // track change) updates this same object rather than sending a new
            // one, so a change to what it says is a new arrival.
            n.summaryChanged.connect(() => root.arrive(n));
            n.bodyChanged.connect(() => root.arrive(n));
            n.closed.connect(() => root.forget(n.id));
        }

        root.arrive(n);
    }

    function arrive(n) {
        const next = root.snapshot(n);

        // A transient notification asks not to be kept; it is a popup or it is
        // nothing.
        if (!next.transient) {
            var kept = [next];
            for (var i = 0; i < root.history.length; i++) {
                if (root.history[i].id !== n.id)
                    kept.push(root.history[i]);
            }
            // Oldest past the limit are let go properly, so their senders hear
            // they were closed rather than assuming they are still shown.
            while (kept.length > root.historyLimit) {
                const dropped = kept.pop();
                if (root.objects[dropped.id])
                    root.objects[dropped.id].expire();
            }
            root.history = kept;
        }

        if (root.shouldPopUp(next))
            root.popUp(next, n.expireTimeout);
        else if (next.transient && root.objects[n.id])
            root.objects[n.id].expire();
    }

    // Critical still interrupts do-not-disturb, because that is what critical
    // means. Nothing interrupts the lock screen: a popup there would put a
    // message preview in front of whoever is standing at the machine.
    function shouldPopUp(r) {
        if (SessionLock.locked)
            return false;
        return !root.doNotDisturb || r.urgency === "critical";
    }

    // expireTimeout is the protocol's own value, in milliseconds: -1 leaves it
    // to the server, 0 asks for the notification never to expire.
    function popUp(r, expireTimeout) {
        const sticky = r.urgency === "critical" || expireTimeout === 0;
        const timeout = expireTimeout > 0 ? expireTimeout : root.defaultTimeout;
        const deadline = sticky ? 0 : Date.now() + timeout;

        var next = [{ id: r.id, deadline: deadline, record: r }];
        for (var i = 0; i < root.popups.length; i++) {
            if (root.popups[i].id !== r.id)
                next.push(root.popups[i]);
        }
        root.popups = next.slice(0, root.popupLimit);
    }

    // The object is gone -- dismissed, expired, or closed by its own app. Its
    // record goes with it: a notification the app withdrew (a message read on
    // another device) should not linger as though it were still news.
    function forget(id) {
        delete root.objects[id];
        delete root.held[id];
        delete root.released[id];
        root.history = root.history.filter(r => r.id !== id);
        root.popups = root.popups.filter(p => p.id !== id);
    }

    // ------------------------------------------------------------------ act

    function markSeen(id) {
        root.history = root.history.map(r => r.id === id && !r.seen ? Object.assign({}, r, { seen: true }) : r);
    }

    // Off the screen, still in history. What the popup's close button does.
    function hidePopup(id) {
        root.release(root.popups.filter(p => p.id === id));
        root.popups = root.popups.filter(p => p.id !== id);
        delete root.held[id];
        delete root.released[id];
        root.markSeen(id);
    }

    // A transient notification has nowhere to go once its popup does, so it is
    // closed there and then rather than left tracked with nothing showing it.
    function release(leaving) {
        for (var i = 0; i < leaving.length; i++) {
            const n = root.objects[leaving[i].id];
            if (leaving[i].record.transient && n)
                n.expire();
        }
    }

    function hold(id, holding) {
        if (holding) {
            root.held[id] = true;
        } else if (root.held[id]) {
            delete root.held[id];
            root.released[id] = Date.now();
        }
    }

    // Gone for good. What the history panel's close button does.
    function dismiss(id) {
        const n = root.objects[id];
        if (n)
            n.dismiss();
        root.forget(id);
    }

    // The action, or with no identifier the sender's default. Invoking closes a
    // notification that is not resident, which reaches forget() through its
    // closed signal; a resident one only stops being news.
    function activate(id, identifier) {
        const n = root.objects[id];
        const r = root.record(id);
        root.hidePopup(id);
        if (!n || !r)
            return;
        const wanted = identifier || "default";
        for (var i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === wanted) {
                n.actions[i].invoke();
                return;
            }
        }
    }

    function clearAll() {
        const ids = Object.keys(root.objects);
        for (var i = 0; i < ids.length; i++)
            root.objects[ids[i]].dismiss();
        root.objects = ({});
        root.held = ({});
        root.released = ({});
        root.history = [];
        root.popups = [];
    }

    function openHistory() {
        root.historyOpen = true;
    }

    function closeHistory() {
        root.historyOpen = false;
    }

    function toggleHistory() {
        root.historyOpen = !root.historyOpen;
    }

    // Opening the history is what reading it means, so everything in it is
    // seen the moment it is up rather than one card at a time. The bell does
    // not care: it answers to what is kept, not to what is unseen.
    onHistoryOpenChanged: {
        if (root.historyOpen)
            root.history = root.history.map(r => r.seen ? r : Object.assign({}, r, { seen: true }));
    }

    function setDoNotDisturb(on) {
        if (root.doNotDisturb === on)
            return;
        root.doNotDisturb = on;
        // Going quiet takes what is already up off the screen too, except
        // what would have broken through anyway.
        if (on)
            root.popups = root.popups.filter(p => p.record.urgency === "critical");
        dndWrite.command = ["sh", "-c", "mkdir -p \"$1\" && printf '%s\\n' \"$2\" > \"$1/do-not-disturb\"", "sh", root.statePath, on ? "on" : "off"];
        dndWrite.running = true;
    }

    // ------------------------------------------------------------ plumbing

    NotificationServer {
        id: server

        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: true

        onNotification: n => root.receive(n)
    }

    // Takes popups off the screen as their time runs out. One timer for all of
    // them, rather than one each, and only while there is something to time.
    Timer {
        interval: 250
        repeat: true
        running: root.popups.length > 0

        onTriggered: {
            const now = Date.now();
            const next = root.popups.filter(p => p.deadline === 0 || p.deadline > now || root.held[p.id]
                || (root.released[p.id] || 0) + 1500 > now);
            if (next.length !== root.popups.length) {
                root.release(root.popups.filter(p => next.indexOf(p) === -1));
                root.popups = next;
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    // Anything that arrived while locked went straight to history, unseen, and
    // the bell is up on the way back in. Nothing replays as popups.
    Connections {
        target: SessionLock
        function onLockedChanged() {
            if (SessionLock.locked)
                root.popups = [];
        }
    }

    FileView {
        id: dndFile

        path: root.statePath + "/do-not-disturb"
        blockLoading: true
        printErrors: false

        onLoaded: root.doNotDisturb = dndFile.text().trim() === "on"
    }

    Process {
        id: dndWrite
    }

    IpcHandler {
        target: "notificationCenter"

        // What Super+Shift+N calls.
        function toggle(): string {
            root.toggleHistory();
            return root.historyOpen ? "opened" : "closed";
        }

        function open(): string {
            root.openHistory();
            return "opened";
        }

        function close(): string {
            root.closeHistory();
            return "closed";
        }

        // on, off or toggle.
        function dnd(value: string): string {
            if (value === "on")
                root.setDoNotDisturb(true);
            else if (value === "off")
                root.setDoNotDisturb(false);
            else if (value === "toggle" || value === "")
                root.setDoNotDisturb(!root.doNotDisturb);
            else
                return "expected on, off or toggle";
            return root.doNotDisturb ? "do not disturb on" : "do not disturb off";
        }

        function clear(): string {
            root.clearAll();
            return "cleared";
        }

        function status(): string {
            return "history=" + root.history.length
                + " unseen=" + root.unseen
                + " popups=" + root.popups.length
                + " dnd=" + root.doNotDisturb
                + " open=" + root.historyOpen;
        }
    }
}
