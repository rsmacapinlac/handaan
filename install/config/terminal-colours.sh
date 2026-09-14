#!/bin/bash
# Colour files for the terminal apps handaan installs, and btop's way to its own.
#
# handaan-wallpaper-set writes these on every wallpaper change, and the first of
# those is at the first login. Writing them now means a terminal opened before
# then is already coloured, in the fallback palette. See ADR 0009.

log_info "Writing terminal app colour files..."
"$HANDAAN_PATH/bin/handaan-theme-render" || log_warning "Some terminal app colour files were not written"

# btop finds a theme only by name, in its own themes directory -- a path in
# color_theme silently falls back to the default -- so the rendered file is
# linked in there. A link rather than a copy, because the file it points at
# changes with every wallpaper. Nothing is written through a ~/.config/btop
# that is itself a link into another tree.
btop_themes="$HOME/.config/btop/themes"
btop_link="$btop_themes/handaan.theme"
if [[ -e $btop_link || -L $btop_link ]]; then
    log_info "btop's theme link is already in place"
elif [[ -L $HOME/.config/btop || -L $btop_themes ]]; then
    log_warning "Not linking btop's theme: ~/.config/btop is a symlink into another tree"
else
    mkdir -p "$btop_themes"
    ln -s "$HANDAAN_STATE/theme/btop.theme" "$btop_link"
    log_success "Linked btop's theme"
fi
