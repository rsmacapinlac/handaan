echo "Replace the empty lua54 shim with the real package so Hyprland can start"

# The installer used to fabricate a lua54 package that only declared
# provides=('lua54') and shipped no files. That satisfied pacman's dependency
# resolution for libinput while leaving liblua5.4.so.5.4 absent -- and because
# it installed under the name lua54, it also shadowed extra/lua54, which is a
# real package that ships the library.
#
# The visible symptom is a machine that installs without error and then cannot
# start a desktop: Hyprland exits with "error while loading shared libraries:
# liblua5.4.so.5.4", greetd restart-loops to start-limit-hit, and the screen
# stays black.
#
# Idempotent: a machine already carrying a lua54 that owns files is left alone.

if ! pacman -Q lua54 &>/dev/null; then
    echo "  lua54 is not installed; nothing to repair"
    exit 0
fi

if [[ -n $(pacman -Ql lua54 2>/dev/null) ]]; then
    echo "  lua54 owns files already; nothing to repair"
    exit 0
fi

echo "  lua54 is installed but owns no files -- this is the shim; replacing it"
sudo pacman -S --noconfirm lua54

if [[ -e /usr/lib/liblua5.4.so.5.4 ]]; then
    echo "  liblua5.4.so.5.4 is present"
else
    echo "  liblua5.4.so.5.4 is still missing after reinstall" >&2
    exit 1
fi
