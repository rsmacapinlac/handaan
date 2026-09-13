echo "Uninstall waybar, now that Quickshell is the only bar"

# waybar stayed installed, its unit un-enabled, as a fallback while the
# Quickshell bar grew to parity. The last thing only it offered was a power
# button, and that menu now lives in the shell (Ui/PowerMenu.qml), so the
# package and its seed under config/waybar/ are gone. A fresh install no longer
# lists it in install/desktop.packages; this removes it from a machine that
# already has it.
#
# ~/.config/waybar is not touched here. Whether it is handaan's leftover or
# the user's own is 1789328851's question.
#
# Idempotent: nothing is done when the package is already absent.

if pacman -Q waybar >/dev/null 2>&1; then
    # Stop a copy started by hand before the binary goes away underneath it.
    systemctl --user disable --now waybar.service >/dev/null 2>&1 || true
    sudo pacman -Rns --noconfirm waybar
    echo "  removed waybar"
else
    echo "  waybar is not installed; nothing to remove"
fi
