echo "Install matugen, so the desktop's colours can follow the wallpaper"

# handaan-wallpaper-set now takes a palette from each new wallpaper with matugen
# and recolours Hyprland and the shell with it (see ADR 0007). Without
# the package every wallpaper change logs an error and the colours stay put --
# nothing breaks, the theme simply never moves. A fresh install gets matugen
# from install/desktop.packages.
#
# The first derived palette arrives with the next wallpaper change or the next
# login; this does not recolour a running session.
#
# Idempotent: an installed matugen is left alone.

if pacman -Q matugen &>/dev/null; then
    echo "  matugen is already installed; nothing to do"
    exit 0
fi

sudo pacman -S --needed --noconfirm matugen
