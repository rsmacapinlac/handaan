echo "Stop hyprpaper drawing the Hyprland splash message over the wallpaper"

# config/hypr/hyprpaper.conf now seeds splash = false. That seed never reaches
# a machine that already has ~/.config/hypr/hyprpaper.conf, so:
#
#   1. add splash = false to it, unless it already says something about splash
#   2. restart hyprpaper, which reads its config only at start, and put the
#      wallpaper back
#
# A splash line already there is yours, so it is left as it is.
#
# Idempotent: every step checks before it acts.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"

conf="$HOME/.config/hypr/hyprpaper.conf"

# --- 1. hyprpaper.conf --------------------------------------------------------

if [[ -L $conf ]]; then
    echo "  ~/.config/hypr/hyprpaper.conf is a symlink into another tree; left in place"
    exit 0
elif [[ ! -f $conf ]]; then
    echo "  no ~/.config/hypr/hyprpaper.conf; nothing to change"
    exit 0
elif grep -Eq '^[[:space:]]*splash[[:space:]]*=' "$conf"; then
    echo "  hyprpaper.conf already sets splash; left as it is"
    exit 0
fi

printf '\n# hyprpaper draws a Hyprland splash message over the wallpaper unless told not to.\nsplash = false\n' >> "$conf"
echo "  added splash = false to ~/.config/hypr/hyprpaper.conf"

# --- 2. hyprpaper -------------------------------------------------------------

if systemctl --user --quiet is-active hyprpaper.service 2>/dev/null; then
    systemctl --user restart hyprpaper.service
    "$HANDAAN_PATH/bin/handaan-wallpaper-set" --restore || true
    echo "  restarted hyprpaper"
else
    echo "  hyprpaper is not running; it reads the change at the next login"
fi
