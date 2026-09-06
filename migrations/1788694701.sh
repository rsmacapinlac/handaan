echo "Fix the lock screen: dead colors.conf source, and a stale capslock script path"

# hyprlock.conf had two dangling paths, both pointing at files that were never
# seeded on any machine:
#
#   source = $HOME/.config/hypr/colors.conf
#
# ~/.config/hypr/colors.conf does not exist -- the generated Catppuccin palette
# lives under default/hypr/colors.conf, read live out of $HANDAAN_PATH like
# every other handaan default. With the source missing, every $variable it
# was meant to define ($accent, $text, $surface0, ...) was undefined. Typed
# options (outer_color, font_color, ...) silently fell back to hyprlock's own
# built-in colors, so the whole lock screen was rendering unthemed. Worse, the
# placeholder_text field interpolates $textAlpha/$accentAlpha into a literal
# Pango <span> string -- an undefined variable there is left as literal text
# ("foreground=\"#$textAlpha\""), which is not a valid color, so Pango's markup
# parser fails and hyprlock falls back to showing the raw, unparsed markup
# source instead of "Logged in as <name>".
#
#   text = cmd[update:200]$HOME/.config/hypr/hyprlock-capslock $yellowAlpha
#
# ~/.config/hypr/hyprlock-capslock never existed either -- the script is
# bin/handaan-hyprlock-capslock, on $PATH already. Every 200ms poll logged
# "No such file or directory" and the caps lock warning never appeared.
#
# Idempotent: a hyprlock.conf without the old paths is left alone.

hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"

if [[ ! -f $hyprlock_conf ]]; then
    echo "  $hyprlock_conf does not exist; nothing to repair"
    exit 0
fi

changed=0

# Plain Python string replacement -- bash's ${var//pattern/repl} treats
# pattern as a glob, and "cmd[update:200]" contains a `[...]` character class
# that silently fails to match literally.
replace_literal() {
    python3 - "$hyprlock_conf" "$1" "$2" <<'PYEOF'
import sys
path, old, new = sys.argv[1:4]
with open(path) as f:
    contents = f.read()
if old not in contents:
    sys.exit(1)
with open(path, "w") as f:
    f.write(contents.replace(old, new))
PYEOF
}

old_source='source = $HOME/.config/hypr/colors.conf'
new_source='# $HOME/.config/hypr/colors.conf was never seeded on any machine -- the
# generated palette lives under default/, read live so a `git pull` updates it.
source = $HANDAAN_PATH/default/hypr/colors.conf'

if replace_literal "$old_source" "$new_source"; then
    echo "  repointed the colors.conf source at \$HANDAAN_PATH/default/hypr/colors.conf"
    changed=1
else
    echo "  colors.conf source already fixed (or customized); leaving it"
fi

old_capslock='text = cmd[update:200]$HOME/.config/hypr/hyprlock-capslock $yellowAlpha'
new_capslock='text = cmd[update:200]handaan-hyprlock-capslock $yellowAlpha'

if replace_literal "$old_capslock" "$new_capslock"; then
    echo "  repointed the capslock label at handaan-hyprlock-capslock on \$PATH"
    changed=1
else
    echo "  capslock label already fixed (or customized); leaving it"
fi

if [[ $changed == 0 ]]; then
    echo "  nothing to repair"
fi
