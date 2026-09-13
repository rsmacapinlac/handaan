// Locking the session, and getting back in.
//
// A singleton for the reason SessionControl is one: the lock surfaces in
// Ui/LockScreen.qml exist only while something is showing them, and a thing
// that does not exist cannot receive the IPC call asking it to appear. This is
// always resident, holds whether the session is locked, and carries the
// `sessionLock` target that bin/handaan-session-lock reaches.
//
// The two are named differently on purpose: a type sharing a name with a
// singleton imported into it shadows that singleton silently.
//
// Everything the surfaces show lives here rather than in them: the bar is not
// the only thing drawn once per monitor, and the lock is too. Keystrokes land
// on whichever monitor the compositor gives the keyboard to, and every screen
// shows the same dots and the same answer because they all read this one copy.
//
// There is deliberately no IPC call that unlocks. The only way out of a lock is
// PAM saying yes to what was typed on the lock surface.
//
// A preview draws the same surfaces as ordinary overlays without locking
// anything, so the surface and the password check can be tried without the
// risk of being shut out by a lock screen that turns out not to work. The
// preview runs a real PAM check, and pam_faillock counts a wrong password there
// as it would anywhere else.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    property bool locked: false
    property bool previewing: false
    readonly property bool showing: root.locked || root.previewing

    // The wallpaper hyprpaper is showing, as handaan-wallpaper-set records it.
    // Re-read every time the lock comes up, so a wallpaper changed since the
    // shell started is the one the lock shows. Empty when there is none, and
    // the surfaces fall back to a plain colour.
    property string wallpaper: ""

    // What has been typed and not yet sent. Never exposed over IPC.
    property string buffer: ""
    property bool checking: false

    // Why the last attempt did not unlock, in words. Cleared by the next
    // keystroke, so it describes the attempt you made rather than lingering
    // over the one you are making.
    property string failure: ""

    property bool capsLock: false

    // Bumped on every failed attempt, so a surface can react to a second
    // failure with the same message as the first.
    property int failures: 0

    // Set once PAM has been given the password for this attempt. A stack that
    // asks a second question -- a one-time code, say -- is one this lock does
    // not know how to answer, and it must not be handed the password twice.
    property bool responded: false

    // A notice PAM sent alongside the prompt. pam_faillock uses one to say the
    // account is temporarily locked, which is the real reason a correct
    // password is being refused, and much more useful than "wrong password".
    property string notice: ""

    // Present while the session is locked. $XDG_RUNTIME_DIR is cleared at
    // logout, so a marker found at startup can only mean the shell went away
    // mid-lock -- a crash, or handaan-lid-switch restarting it -- and the
    // compositor is still holding the session locked behind a dead surface.
    // Locking again at once is what puts a working lock screen back in front
    // of it; misc:allow_session_lock_restore in default/hypr/look.lua is what
    // lets the new process take the lock over.
    readonly property string markerPath: {
        const runtime = Quickshell.env("XDG_RUNTIME_DIR");
        return runtime ? runtime + "/handaan-session-locked" : "";
    }

    function lock() {
        if (root.locked)
            return false;
        root.previewing = false;
        root.prepare();
        root.locked = true;
        if (root.markerPath !== "")
            Quickshell.execDetached(["touch", root.markerPath]);
        return true;
    }

    function preview() {
        if (root.locked)
            return false;
        root.prepare();
        root.previewing = true;
        return true;
    }

    function closePreview() {
        if (!root.previewing)
            return;
        root.reset();
        root.previewing = false;
    }

    // The compositor refused the lock or took it away -- usually because some
    // other locker already holds the session. This one stands down rather than
    // claiming a lock it does not have. There is no second locker to hand over
    // to, and someone who asked for a lock must not be left at an open session
    // believing it locked, so it says so as loudly as the desktop allows.
    function lockLost() {
        console.error("SessionLock: the compositor refused or ended the lock; the session is not locked");
        root.reset();
        root.locked = false;
        root.removeMarker();
        Quickshell.execDetached(["notify-send", "--urgency=critical", "The session is not locked",
            "The compositor refused the lock screen, or ended it without a password."]);
    }

    function type(text) {
        if (root.checking)
            return;
        root.failure = "";
        root.notice = "";
        if (root.buffer.length === 0)
            root.checkCapsLock();
        root.buffer += text;
    }

    function erase() {
        if (root.checking)
            return;
        root.failure = "";
        root.buffer = root.buffer.slice(0, -1);
    }

    function clear() {
        if (root.checking)
            return;
        root.failure = "";
        root.buffer = "";
    }

    function submit() {
        if (root.checking || root.buffer.length === 0)
            return;
        root.failure = "";
        root.notice = "";
        root.responded = false;
        root.checking = true;
        if (!pam.start())
            root.fail("The password check could not start");
    }

    function checkCapsLock() {
        capsLockCheck.running = true;
    }

    function prepare() {
        root.reset();
        wallpaperFile.reload();
        root.checkCapsLock();
    }

    function reset() {
        root.checking = false;
        if (pam.active)
            pam.abort();
        root.buffer = "";
        root.failure = "";
        root.notice = "";
        root.responded = false;
    }

    function fail(reason) {
        root.checking = false;
        root.buffer = "";
        root.failure = reason;
        root.failures += 1;
        root.checkCapsLock();
    }

    function succeed() {
        root.checking = false;
        root.buffer = "";
        root.failure = "";
        root.notice = "";
        if (root.locked) {
            root.locked = false;
            root.removeMarker();
        }
        root.previewing = false;
    }

    function removeMarker() {
        if (root.markerPath !== "")
            Quickshell.execDetached(["rm", "-f", root.markerPath]);
    }

    // `login` is the stack a console login uses, and the one hyprlock used
    // before this replaced it, so the lock refuses and accepts exactly what
    // logging in does, faillock included, with no PAM file of its own to
    // install into /etc.
    PamContext {
        id: pam

        config: "login"

        onPamMessage: {
            if (!pam.responseRequired) {
                if (pam.message.length > 0)
                    root.notice = pam.message.trim();
                return;
            }
            if (root.responded) {
                root.fail("This machine asks for more than a password");
                pam.abort();
                return;
            }
            root.responded = true;
            const answer = root.buffer;
            root.buffer = "";
            pam.respond(answer);
        }

        onCompleted: result => {
            if (!root.checking)
                return;
            if (result === PamResult.Success)
                root.succeed();
            else if (result === PamResult.MaxTries)
                root.fail(root.notice || "Too many failed attempts");
            else if (result === PamResult.Failed)
                root.fail(root.notice || "Wrong password");
            else
                root.fail(root.notice || "The password check failed to run");
        }

        onError: error => {
            if (root.checking)
                root.fail("The password check failed to run");
        }
    }

    // Caps Lock only changes when a key is pressed, and every key goes to the
    // lock while it is up, so this runs when the lock appears, on the first
    // keystroke, on the Caps Lock key itself and after a failure -- never on a
    // timer. The compositor is asked rather than the LED, because not every
    // keyboard has one.
    Process {
        id: capsLockCheck

        command: ["hyprctl", "devices", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(this.text).keyboards || [];
                    root.capsLock = keyboards.some(keyboard => keyboard.capsLock === true);
                } catch (e) {
                    root.capsLock = false;
                }
            }
        }
    }

    FileView {
        id: wallpaperFile

        path: Quickshell.env("HOME") + "/.wallpaper"
        printErrors: false

        onLoaded: root.wallpaper = wallpaperFile.text().trim()
        onLoadFailed: root.wallpaper = ""
    }

    Process {
        id: markerCheck

        command: ["test", "-e", root.markerPath]

        onExited: code => {
            if (code === 0)
                root.lock();
        }
    }

    Component.onCompleted: {
        if (root.markerPath !== "")
            markerCheck.running = true;
    }

    IpcHandler {
        target: "sessionLock"

        function lock(): string {
            return root.lock() ? "locked" : "already locked";
        }

        function preview(): string {
            return root.preview() ? "previewing" : "locked; nothing to preview over";
        }

        function closePreview(): string {
            root.closePreview();
            return "closed";
        }

        function status(): string {
            const state = root.locked ? "locked" : root.previewing ? "previewing" : "unlocked";
            return state + " wallpaper=" + (root.wallpaper || "none");
        }
    }
}
