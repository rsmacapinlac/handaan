// The optional applications this machine could install, and which it already has.
//
// A singleton, for the reason Maintenance.qml is one: the bar is built once per
// monitor through `Variants { model: Quickshell.screens }`, so a catalogue that
// polled for itself would run `pacman -T` once per screen for an answer that is
// identical on every screen. The catalogue belongs to the process; the
// installer is a view onto it.
//
// It must therefore be reached as `qs.Commons.AppCatalog`, never by relative
// path: a pragma Singleton imported by path is instantiated once per importing
// file, so each importer would silently get its own empty copy.
//
// The surface that draws this is Ui/Installer.qml. The two are named
// differently on purpose -- a type sharing a name with a singleton imported
// into it would shadow the singleton silently, which is the trap AGENTS.md
// records for `Palette`, and the same reason Maintenance is not called Updates.
//
// "Apps" here means handaan's own sense of the word -- a directory under
// ~/.config/handaan/apps/ holding meta, packages, install.sh and config/ --
// not desktop entries. Quickshell's launcher-side types are DesktopEntries and
// DesktopEntry, which is what a launcher would read instead.
//
// Everything here comes from handaan-apps-manifest, so the shell holds no
// opinion about what an app is or when one counts as installed. Run it in a
// terminal to see exactly what the installer sees.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // One entry per app directory: { name, summary, installed }. Empty until
    // the first poll returns, which `loaded` is what distinguishes -- an empty
    // catalogue and an unread one look identical otherwise, and only one of
    // them should say "no apps found".
    property var entries: []
    property bool loaded: false
    property bool polling: false

    // Set when the manifest could not be read at all. Kept separate from an
    // empty catalogue: "nothing offered" and "the check failed" are different
    // answers and the installer says so differently.
    property string error: ""

    // Whether the installer surface is up. Held here rather than in the
    // surface because the surface is loaded on demand, and a thing that is not
    // loaded cannot receive the IPC call asking it to appear.
    property bool installerOpen: false

    readonly property int pendingCount: {
        var pending = 0;
        for (var i = 0; i < root.entries.length; i++) {
            if (!root.entries[i].installed)
                pending += 1;
        }
        return pending;
    }

    // Resolved rather than looked up on PATH, and run as argv rather than
    // through a shell -- the same reasoning as Maintenance.command.
    readonly property string handaanPath: Quickshell.env("HANDAAN_PATH") || (Quickshell.env("HOME") + "/.local/share/handaan")

    function refresh() {
        if (!poll.running)
            poll.running = true;
    }

    function open() {
        root.refresh();
        root.installerOpen = true;
    }

    function close() {
        root.installerOpen = false;
    }

    // Hand the names to a terminal and forget about them. The install is long,
    // needs sudo and prints pacman output, none of which belongs in the shell's
    // process -- and execDetached double-forks, so a terminal outliving the
    // shell cannot take the bar down with it.
    //
    // Nothing here waits for the result. handaan-apps-install pokes
    // `maintenance refresh` when it finishes, and the catalogue re-reads itself
    // the next time the installer opens, so neither side has to poll the other.
    function install(names) {
        if (!names || names.length === 0)
            return;
        Quickshell.execDetached([root.handaanPath + "/bin/handaan-apps-terminal"].concat(names));
    }

    IpcHandler {
        target: "appCatalog"

        // What `handaan apps` calls. Opening deliberately re-reads rather than
        // trusting whatever the last poll found: an app may have been installed
        // from a terminal since, and a picker showing a stale tick is worse
        // than one that takes 200ms to appear.
        function open(): string {
            root.open();
            return "opening";
        }

        function close(): string {
            root.close();
            return "closed";
        }

        function refresh(): string {
            root.refresh();
            return "refreshing";
        }

        // The catalogue as the shell currently holds it, which is not the same
        // as running handaan-apps-manifest again. Worth having when a terminal
        // and the installer disagree and the question is which one is behind.
        function status(): string {
            if (root.error)
                return "error: " + root.error;
            if (!root.loaded)
                return "not read yet";
            return "apps=" + root.entries.length
                + " pending=" + root.pendingCount
                + " open=" + root.installerOpen
                + " polling=" + root.polling;
        }
    }

    Process {
        id: poll

        command: [root.handaanPath + "/bin/handaan-apps-manifest"]
        onRunningChanged: root.polling = running

        // A non-zero exit means the catalogue could not be read -- no jq, an
        // unreadable apps directory. Reporting that as an empty list would tell
        // the user they have no apps to install, which is a different and
        // wrong answer.
        onExited: function (exitCode) {
            if (exitCode !== 0) {
                root.error = "handaan-apps-manifest exited " + exitCode;
                root.loaded = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                // Parse into a local and assign once. Assigning as each entry
                // is parsed would publish a half-built catalogue that bindings
                // would see and redraw through.
                var parsed = [];
                try {
                    parsed = JSON.parse(this.text);
                } catch (e) {
                    root.error = "could not parse the catalogue: " + e;
                    root.loaded = true;
                    return;
                }

                if (!Array.isArray(parsed)) {
                    root.error = "the catalogue was not a list";
                    root.loaded = true;
                    return;
                }

                root.error = "";
                root.entries = parsed;
                root.loaded = true;
            }
        }
    }
}
