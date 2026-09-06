// What is waiting for the machine's owner to do something about it.
//
// A singleton, and that is the whole point of the file. Bar.qml instantiates
// its surface once per monitor through `Variants { model: Quickshell.screens }`,
// so a widget that polled for itself would run the checks once per screen --
// two concurrent `git fetch`es into the same repository on a docked laptop,
// twice the pacman database syncs, for one answer that is identical on every
// screen. The poll belongs to the process; the widget is a view onto it.
//
// It must therefore be reached as `qs.Commons.Maintenance`, never by relative
// path: a pragma Singleton imported by path is instantiated once per importing
// file, so each bar would silently get its own copy and the duplication would
// come straight back.
//
// The widget that draws this is modules/Pending.qml. The two are named
// differently on purpose -- a type in modules/ sharing a name with a singleton
// imported into it would shadow the singleton silently, which is the trap
// AGENTS.md records for `Palette`.
//
// Everything here comes from `handaan-pending`, one process rather than three,
// so the shell holds no opinion about how any of it is measured. Run it in a
// terminal to see exactly what the bar sees.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // -1 means "not known", which is deliberately not 0. A missing
    // checkupdates, no origin/main, or no network are all cases where the
    // honest answer is that the check could not run -- reporting them as zero
    // would say the machine is up to date because the question failed.
    property int apps: -1
    property int arch: -1
    property int handaanCommits: -1
    property int handaanMigrations: -1

    // True once a poll has completed, so the widget can tell "nothing waiting"
    // from "nothing measured yet" during the seconds after login.
    property bool polled: false
    property bool polling: false

    function known(value) {
        return value >= 0;
    }

    readonly property int handaan: Math.max(0, root.handaanCommits) + Math.max(0, root.handaanMigrations)

    // Only counts that were actually measured. An unknown source contributes
    // nothing rather than a guess, so the indicator never appears on the
    // strength of a check that failed.
    readonly property int total: Math.max(0, root.apps) + Math.max(0, root.arch) + root.handaan

    // Any source whose check could not answer. The widget does not light up for
    // this -- an indicator that appears because a tool is missing would cry
    // wolf every boot before the network is up -- but the tooltip says so,
    // because "no updates" and "could not check" must not look identical.
    readonly property bool degraded: !root.known(root.apps) || !root.known(root.arch) || !root.known(root.handaanCommits) || !root.known(root.handaanMigrations)

    // Resolved rather than looked up on PATH, and run as argv rather than
    // through a shell. The bar is a systemd user unit whose environment comes
    // from uwsm; $HANDAAN_PATH/bin is on its PATH today, but a poll that
    // silently reports "cannot check" forever if that ever stops being true is
    // a bad way to find out. No shell also means no quoting to get wrong.
    readonly property string handaanPath: Quickshell.env("HANDAAN_PATH") || (Quickshell.env("HOME") + "/.local/share/handaan")

    // --fetch is what makes the handaan count meaningful: without it the
    // comparison is against whatever origin/main was last known locally, so a
    // newly published commit would never show up. It is also the only network
    // access in the poll, which is why nothing else runs it.
    property list<string> command: [root.handaanPath + "/bin/handaan-pending", "--fetch"]

    // Half an hour. The poll syncs a package database and fetches a git remote,
    // and nothing here is worth doing more often than that: an update that
    // landed twenty minutes ago is not more urgent than one that landed now,
    // and a tighter loop would spend battery and bandwidth to say the same
    // thing. Nothing on this widget is time-critical by design.
    property int intervalMs: 30 * 60 * 1000

    function refresh() {
        if (!poll.running)
            poll.running = true;
    }

    Process {
        id: poll

        command: root.command
        onRunningChanged: root.polling = running

        stdout: StdioCollector {
            onStreamFinished: {
                // Parse into locals first and assign once. Assigning field by
                // field as they are parsed would publish a half-updated state
                // that bindings would see and animate through.
                var next = {
                    "apps": -1,
                    "arch": -1,
                    "handaan-commits": -1,
                    "handaan-migrations": -1
                };

                const lines = this.text.split("\n");
                for (const line of lines) {
                    const parts = line.split("\t");
                    if (parts.length < 2)
                        continue;
                    const key = parts[0].trim();
                    const raw = parts[1].trim();
                    if (!(key in next))
                        continue;
                    // "?" is the script's word for "could not check". Anything
                    // unparseable is treated the same way rather than as zero.
                    const value = parseInt(raw, 10);
                    next[key] = (raw === "?" || isNaN(value)) ? -1 : value;
                }

                root.apps = next["apps"];
                root.arch = next["arch"];
                root.handaanCommits = next["handaan-commits"];
                root.handaanMigrations = next["handaan-migrations"];
                root.polled = true;
            }
        }
    }

    // The first poll waits. At login the network is usually not up yet, and a
    // fetch that fails then would leave the handaan count unknown until the
    // next tick half an hour later -- so the delay buys a first answer that is
    // actually an answer.
    Timer {
        running: true
        interval: 20 * 1000
        onTriggered: root.refresh()
    }

    Timer {
        running: true
        repeat: true
        interval: root.intervalMs
        onTriggered: root.refresh()
    }
}
