echo "Stop rofi opening two windows for apps that start slowly, such as Files"

# rofi 2.0 launches a DBusActivatable app over D-Bus, gives the call 1.5s, and
# on a timeout runs the entry's Exec as well. Nautilus takes longer than that to
# start cold, so both land and it opens two windows. config/rofi/config.rasi now
# seeds DBusActivatable: false, so rofi only runs Exec. That seed never reaches
# a machine that already has ~/.config/rofi/config.rasi, so this appends the
# same setting to it, unless it already says something about DBusActivatable.
#
# rofi merges a second configuration block into the first, so appending one
# leaves the rest of the file as it is. rofi reads its config on every launch;
# nothing needs restarting.
#
# Idempotent: a DBusActivatable line already there is left as it is.

conf="$HOME/.config/rofi/config.rasi"

if [[ -L $conf || -L $HOME/.config/rofi ]]; then
    echo "  ~/.config/rofi/config.rasi is a symlink into another tree; left in place"
    echo "  add drun { DBusActivatable: false; } inside its configuration block"
    exit 0
elif [[ ! -f $conf ]]; then
    echo "  no ~/.config/rofi/config.rasi; nothing to change"
    exit 0
elif grep -q 'DBusActivatable' "$conf"; then
    echo "  config.rasi already sets DBusActivatable; left as it is"
    exit 0
fi

cat >> "$conf" <<'RASI'

// rofi gives a D-Bus launch 1.5s, then also runs Exec; an app slower to
// start than that (Nautilus) opens two windows.
configuration {
  drun {
    DBusActivatable: false;
  }
}
RASI
echo "  added DBusActivatable: false to ~/.config/rofi/config.rasi"
