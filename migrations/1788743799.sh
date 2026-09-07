echo "Check whether the old ~/.config symlink sweep deleted a dotfile deployment"

# install/config/seed-config.sh used to delete every symlink under ~/.config
# pointing into ~/workspace or the handaan checkout, down to three levels:
#
#   find "$HOME/.config" -maxdepth 3 -type l -print0
#
# The intent was to break links left behind by a dotfile manager the machine
# had migrated *off*, so `cp -R` could not write through one into the source
# repository. But a machine whose dotfile repository still deploys by symlink
# has migrated off nothing -- those links are its live deployment -- and the
# sweep deleted all of them within the depth limit on every installer run.
#
# handaan cannot undo that. It never knew where the links pointed, and the
# files it deleted were the user's, not its own. What it can do is say so,
# because the failure is quiet: a config directory keeps everything below three
# levels and loses everything above, so an application with a nested config
# tree looks present and simply does not load. That is what it looked like
# here -- ~/.config/nvim kept lua/core/*.lua at depth 4 and lost init.lua at
# depth 2, leaving Neovim with a config directory and no entry point.
#
# The detection below is that same fingerprint: symlinks into ~/workspace
# surviving at depth 4 or more, and none at all at depth 1 to 3. A tree
# deployed by symlink has them at every depth, so the missing shallow ones mean
# something removed exactly what the sweep could reach.

config="$HOME/.config"

if [[ ! -d $config ]]; then
    echo "  no ~/.config; nothing to check"
    exit 0
fi

count_links() {
    find "$config" -mindepth "$1" -maxdepth "$2" -type l 2>/dev/null \
        | while read -r link; do
            target=$(readlink -f "$link" 2>/dev/null || true)
            case "$target" in
                "$HOME"/workspace/*) printf '.' ;;
            esac
        done | wc -c
}

shallow=$(count_links 1 3)
deep=$(count_links 4 12)

if (( deep == 0 )); then
    echo "  no symlinked dotfile deployment under ~/.config; nothing to check"
    exit 0
fi

if (( shallow > 0 )); then
    echo "  symlinks present at every depth; the sweep did not run here"
    exit 0
fi

echo
echo "  WARNING: $deep symlink(s) into ~/workspace survive below ~/.config, and"
echo "  none remain in its top three levels. An older handaan installer deleted"
echo "  symlinks there on every run, so files your dotfile repository deploys"
echo "  shallowly -- ~/.config/nvim/init.lua, ~/.config/kitty/kitty.conf and"
echo "  the like -- are most likely gone."
echo
echo "  handaan cannot restore them; it does not know where they pointed."
echo "  Re-run your dotfile repository's own deployment to put them back."
echo
echo "  The installer no longer does this. It now seeds one file at a time,"
echo "  never deletes, and skips any path another tree already owns."
echo
