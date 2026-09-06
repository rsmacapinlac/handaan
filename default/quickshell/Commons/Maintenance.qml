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
// The widget that draws this is modules/Updates.qml. The two are named
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

    // Work that clears when it is done, which is the only kind the bar shows.
    //
    // `apps` is deliberately not in here. It is parsed and published because
    // handaan-pending reports it and it is worth having in a terminal, but it
    // is a catalogue rather than a chore: the apps directory offers everything
    // its owner might ever want on any machine, so the count is permanently
    // non-zero on every machine that is not all of them at once. Summing it
    // into the number that drives the bar made the indicator permanent, which
    // is the same failure as an animation that never stops -- see
    // modules/Updates.qml.
    //
    // Only counts that were actually measured. An unknown source contributes
    // nothing rather than a guess, so the indicator never appears on the
    // strength of a check that failed.
    readonly property int updates: Math.max(0, root.arch) + root.handaan

    // Whether a given source could be measured is exposed through known()
    // rather than a rolled-up flag. The widget needs to name which check is
    // blind, not merely that one is -- "no updates" and "could not check" must
    // not look identical, and a bare boolean cannot say which.

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

    // Re-poll on demand, so the bar is not stale for up to half an hour after
    // the work is already done. Nothing here changes the machine -- it only
    // asks the same question again -- so it is safe to expose and safe to call
    // from a script that has just finished changing something:
    //
    //   qs -p "$HANDAAN_PATH/default/quickshell" ipc call maintenance refresh
    //
    // bin/handaan-update calls exactly that on its way out. The alternative
    // was a shorter poll interval, which would spend battery and bandwidth on
    // every machine all day to fix a staleness that only matters in the few
    // minutes after an update.
    IpcHandler {
        target: "maintenance"

        function refresh(): string {
            root.refresh();
            return "refreshing";
        }

        // The counts as the bar currently holds them, which is not the same as
        // running handaan-pending again: this is what the widget is drawing,
        // including how stale it is. Worth having when the bar and a terminal
        // disagree and the question is which of them is behind.
        function status(): string {
            if (!root.polled)
                return "not polled yet";
            return "apps=" + root.apps
                + " arch=" + root.arch
                + " handaan-commits=" + root.handaanCommits
                + " handaan-migrations=" + root.handaanMigrations
                + " updates=" + root.updates
                + " polling=" + root.polling;
        }
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
