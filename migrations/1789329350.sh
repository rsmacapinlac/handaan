echo "Lock through the shell's lock screen everywhere, and uninstall hyprlock"

# The shell draws the lock screen now (Commons/SessionLock.qml), and hyprlock
# is gone from install/desktop.packages along with its config/hypr/hyprlock.conf
# seed. Idle, suspend and the lid all lock through hypridle's lock_cmd, and on
# this machine that line is still `pidof hyprlock || hyprlock` -- so removing
# the package without repointing it would leave every one of those locks doing
# nothing, silently, and the machine suspending unlocked.
#
# So the order matters, and each step refuses to go on until the one before
# it holds:
#
#   1. repoint lock_cmd in ~/.config/hypr/hypridle.conf at handaan-session-lock,
#      and add inhibit_sleep = 3 so suspend waits for the lock to be drawn
#   2. restart hypridle, which otherwise keeps running the old lock_cmd
#   3. uninstall hyprlock
#   4. remove ~/.config/hypr/hyprlock.conf
#
# hypridle.conf is yours, so only the exact line handaan seeded is rewritten.
# If anything else in it still starts hyprlock, this stops before uninstalling
# and says which line, rather than breaking a lock you configured.
#
# hyprlock.conf goes whether or not it was edited: its application is gone, so
# nothing will ever read it again, and a config left for an uninstalled app is
# only clutter. An edited copy is kept under $HANDAAN_STATE rather than lost,
# since the edits were yours.
#
# Idempotent: every step checks before it acts.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"
: "${HANDAAN_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/handaan}"

if [[ ! -x $HANDAAN_PATH/bin/handaan-session-lock || ! -f $HANDAAN_PATH/default/quickshell/Commons/SessionLock.qml ]]; then
    echo "  the shell's lock screen is not in $HANDAAN_PATH; pull the checkout first" >&2
    exit 1
fi

# --- 1. hypridle.conf ---------------------------------------------------------

idle_conf="$HOME/.config/hypr/hypridle.conf"

# A symlink belongs to another tree, and writing through it would edit that
# repository rather than this machine.
if [[ -f $idle_conf && ! -L $idle_conf ]]; then
    python3 - "$idle_conf" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f:
    contents = f.read()
new = contents

seeded = re.compile(r'^([ \t]*)lock_cmd[ \t]*=[ \t]*pidof hyprlock \|\| hyprlock[ \t]*(#.*)?$', re.M)
match = seeded.search(new)
if match:
    indent = match.group(1)
    line = indent + "lock_cmd = handaan-session-lock             # the shell's lock screen; asking again while locked is a no-op."
    if not re.search(r'^[ \t]*inhibit_sleep[ \t]*=', new, re.M):
        line += "\n" + indent + "inhibit_sleep = 3                           # hold suspend until the lock is actually on screen."
    new = new[:match.start()] + line + new[match.end():]
    print("  repointed hypridle's lock_cmd at handaan-session-lock")
elif re.search(r'^[ \t]*lock_cmd[ \t]*=[ \t]*handaan-session-lock\b', new, re.M):
    print("  hypridle already locks through handaan-session-lock")
else:
    print("  hypridle's lock_cmd is not the one handaan seeded; left as it is")

if new != contents:
    with open(path, "w") as f:
        f.write(new)
PYEOF
elif [[ -L $idle_conf ]]; then
    echo "  ~/.config/hypr/hypridle.conf is a symlink into another tree; not editing it"
else
    echo "  no ~/.config/hypr/hypridle.conf; nothing to repoint"
fi

# Whatever state it was left in, nothing may still need hyprlock.
if [[ -e $idle_conf ]] && still=$(grep -nE '^[^#]*hyprlock' "$idle_conf"); then
    echo "  ~/.config/hypr/hypridle.conf still starts hyprlock:" >&2
    printf '    %s\n' "$still" >&2
    echo "  Point it at handaan-session-lock, then run handaan migrate again." >&2
    echo "  hyprlock stays installed until then, so the session still locks." >&2
    exit 1
fi

# --- 2. hypridle --------------------------------------------------------------

# try-restart touches a running hypridle only, so from a TTY with no session
# this is a no-op and the next login reads the new file anyway.
if ! systemctl --user try-restart hypridle.service 2>/dev/null; then
    echo "  could not restart hypridle; it may still run the old lock_cmd until you log out" >&2
fi

# --- 3. hyprlock --------------------------------------------------------------

if pacman -Q hyprlock >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm hyprlock
    echo "  removed hyprlock"
else
    echo "  hyprlock is not installed; nothing to remove"
fi

# --- 4. hyprlock.conf ---------------------------------------------------------

lock_conf="$HOME/.config/hypr/hyprlock.conf"

if [[ ! -e $lock_conf && ! -L $lock_conf ]]; then
    echo "  no ~/.config/hypr/hyprlock.conf; nothing to remove"
    exit 0
fi

# A symlink is another tree's deployment, and that tree decides what it ships.
if [[ -L $lock_conf || ! -f $lock_conf ]]; then
    echo "  ~/.config/hypr/hyprlock.conf is not a plain file, so another tree owns it; left in place"
    exit 0
fi

# Unedited means byte-for-byte a version handaan shipped (or one 1788694701
# repaired into one). A shallow clone has no history to tell, and "could not
# tell" is treated as edited, so the copy is kept.
shipped_copy=0
if [[ $(git -C "$HANDAAN_PATH" rev-parse --is-shallow-repository) == false ]]; then
    blob=$(git hash-object --no-filters -- "$lock_conf")
    while read -r commit; do
        if [[ $(git -C "$HANDAAN_PATH" rev-parse -q --verify "$commit:config/hypr/hyprlock.conf" 2>/dev/null) == "$blob" ]]; then
            shipped_copy=1
            break
        fi
    done < <(git -C "$HANDAAN_PATH" rev-list HEAD -- config/hypr/hyprlock.conf)
fi

if (( shipped_copy )); then
    rm "$lock_conf"
    echo "  removed ~/.config/hypr/hyprlock.conf -- it was one handaan shipped, unedited"
else
    kept="$HANDAAN_STATE/retired-config/hypr/hyprlock.conf.$(date +%s)"
    mkdir -p "$(dirname "$kept")"
    mv "$lock_conf" "$kept"
    echo "  removed ~/.config/hypr/hyprlock.conf; it had edits, so a copy is kept at $kept"
fi
