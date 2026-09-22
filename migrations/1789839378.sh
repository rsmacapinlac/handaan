echo "Let the bar reload itself when its QML changes"

# default/systemd/user/quickshell.service no longer sets
# QS_DISABLE_FILE_WATCHER=1, so Quickshell watches default/quickshell and
# reloads the running shell when a file under it changes. Adding a new QML type
# or singleton still needs a real restart -- the type registry is built once at
# launch -- but editing an existing one no longer does.
#
# systemd reads user units from ~/.config/systemd/user, so install/config
# copies them there rather than pointing at the tree. That copy is what a
# machine actually runs, and a git pull never touches it: without this, the
# checkout would say the watcher is on while the unit running the shell still
# said it was off.
#
# Every handaan unit is recopied rather than just this one, which is what
# install/config/seed-config.sh does on a fresh machine. Units are handaan's,
# not yours, so there is nothing here to preserve -- and the copies have
# already drifted for other reasons (a stale comment naming mako, retired in
# 1789361075).
#
# Idempotent: recopying a file that already matches changes nothing, and the
# shell is restarted only if it is already up.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"

unit="$HANDAAN_PATH/default/systemd/user/quickshell.service"

if [[ ! -f $unit ]]; then
    echo "  no $unit; pull the checkout first" >&2
    exit 1
elif grep -q '^Environment=QS_DISABLE_FILE_WATCHER' "$unit"; then
    echo "  $unit still disables the file watcher; pull the checkout first" >&2
    exit 1
fi

dest_dir="$HOME/.config/systemd/user"
mkdir -p "$dest_dir"

copied=0
for src in "$HANDAAN_PATH"/default/systemd/user/*.service; do
    [[ -e $src ]] || continue
    dest="$dest_dir/$(basename "$src")"

    # A symlink belongs to another tree, the same rule the seed follows.
    if [[ -L $dest ]]; then
        echo "  $(basename "$src") is a symlink into another tree; left in place"
        continue
    fi

    if cmp -s "$src" "$dest"; then
        continue
    fi

    cp -f "$src" "$dest"
    copied=$((copied + 1))
    echo "  updated $(basename "$src")"
done

if (( copied == 0 )); then
    echo "  every unit already matches the tree"
    exit 0
fi

systemctl --user daemon-reload >/dev/null 2>&1 || true

# Only if it is already running. On a headless target -- the LXC box, or a TTY
# with no graphical session -- a restart would start a shell with nothing to
# draw on, and the unit is pulled in by graphical-session.target anyway.
if systemctl --user is-active --quiet quickshell.service; then
    systemctl --user restart quickshell.service
    echo "  restarted quickshell.service; its file watcher is now on"
else
    echo "  quickshell.service is not running; the new unit applies at next login"
fi
