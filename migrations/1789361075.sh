echo "Uninstall mako, now that the Quickshell shell is the only notification daemon"

# mako stayed installed, its unit masked by 1789334343, as the fallback while
# the shell's notifications (Commons/NotificationCenter.qml) proved themselves.
# A fresh install no longer lists it in install/desktop.packages or seeds
# config/mako; this does the same on a machine that already has both.
#
#   1. uninstall mako
#   2. remove the mask, which is a dangling link to /dev/null once the unit is gone
#   3. remove ~/.config/mako/config
#
# A mako still running -- only on a machine that skipped 1789334343 -- is not
# stopped. It keeps notifications working for this session, and with its
# package gone the shell claims the name at the next login.
#
# The config goes whether or not it was edited: nothing will ever read it
# again. An edited copy is kept under $HANDAAN_STATE rather than lost, since the
# edits were yours. A symlink belongs to another tree and is left alone.
#
# Idempotent: every step checks before it acts.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"
: "${HANDAAN_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/handaan}"

if [[ ! -f $HANDAAN_PATH/default/quickshell/Commons/NotificationCenter.qml ]]; then
    echo "  the shell's notification daemon is not in $HANDAAN_PATH; pull the checkout first" >&2
    exit 1
fi

# --- 1. mako ------------------------------------------------------------------

if pacman -Q mako >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm mako
    echo "  removed mako"
else
    echo "  mako is not installed; nothing to remove"
fi

# --- 2. the mask --------------------------------------------------------------

mask="$HOME/.config/systemd/user/mako.service"

if [[ -L $mask && $(readlink "$mask") == /dev/null ]]; then
    # unmask needs a user manager; from a TTY with none, the link is the mask.
    systemctl --user unmask mako.service >/dev/null 2>&1 || rm -f "$mask"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    echo "  removed the mask on mako.service"
else
    echo "  mako.service is not masked; nothing to remove"
fi

# --- 3. ~/.config/mako --------------------------------------------------------

conf_dir="$HOME/.config/mako"
conf="$conf_dir/config"

if [[ -L $conf_dir || -L $conf ]]; then
    echo "  ~/.config/mako is a symlink into another tree; left in place"
    exit 0
fi

if [[ ! -e $conf ]]; then
    echo "  no ~/.config/mako/config; nothing to remove"
elif [[ ! -f $conf ]]; then
    echo "  ~/.config/mako/config is not a plain file; left in place"
    exit 0
else
    # Unedited means byte-for-byte a version handaan shipped. A shallow clone
    # has no history to tell, and "could not tell" is treated as edited.
    shipped_copy=0
    if [[ $(git -C "$HANDAAN_PATH" rev-parse --is-shallow-repository) == false ]]; then
        blob=$(git hash-object --no-filters -- "$conf")
        while read -r commit; do
            if [[ $(git -C "$HANDAAN_PATH" rev-parse -q --verify "$commit:config/mako/config" 2>/dev/null) == "$blob" ]]; then
                shipped_copy=1
                break
            fi
        done < <(git -C "$HANDAAN_PATH" rev-list HEAD -- config/mako/config)
    fi

    if (( shipped_copy )); then
        rm "$conf"
        echo "  removed ~/.config/mako/config -- it was one handaan shipped, unedited"
    else
        kept="$HANDAAN_STATE/retired-config/mako/config.$(date +%s)"
        mkdir -p "$(dirname "$kept")"
        mv "$conf" "$kept"
        echo "  removed ~/.config/mako/config; it had edits, so a copy is kept at $kept"
    fi
fi

# Only if nothing else of yours is in it.
if rmdir "$conf_dir" 2>/dev/null; then
    echo "  removed the empty ~/.config/mako"
fi
