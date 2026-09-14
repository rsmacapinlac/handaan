echo "Colour kitty, Neovim, btop, lazygit and nmtui from the wallpaper"

# The desktop's colours already follow the wallpaper (ADR 0007). The terminal
# apps handaan installs now do too, from colour files handaan-theme-render
# writes into $HANDAAN_STATE/theme on every wallpaper change (ADR 0009). This
# writes the first set now, rather than at the next wallpaper change, and gives
# btop its way to them:
#
#   - ~/.config/btop/themes/handaan.theme, a link to the rendered theme, since
#     btop finds themes only by name in that directory
#   - ~/.config/btop/btop.conf choosing it, only if there is no btop.conf yet --
#     an existing one is yours, and says which theme you picked
#
# lazygit and nmtui are pointed at their files by default/shell/env-bootstrap,
# which the session reads at login, so they follow from the next login with
# nothing to change here.
#
# kitty and Neovim read their colours only from your own config, which this
# does not touch; the lines to add are printed at the end.
#
# Idempotent: nothing is written over a file or link that is already there.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"
: "${HANDAAN_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/handaan}"
export HANDAAN_PATH HANDAAN_STATE

"$HANDAAN_PATH/bin/handaan-theme-render" \
    || echo "  some colour files were not written; see the warnings above"

btop_dir="$HOME/.config/btop"
if [[ -L $btop_dir || -L $btop_dir/themes ]]; then
    echo "  ~/.config/btop is a symlink into another tree; not writing into it"
    echo "  link $HANDAAN_STATE/theme/btop.theme into its themes/ and set color_theme = \"handaan\" there"
else
    if [[ -e $btop_dir/themes/handaan.theme || -L $btop_dir/themes/handaan.theme ]]; then
        echo "  btop's theme link is already in place"
    else
        mkdir -p "$btop_dir/themes"
        ln -s "$HANDAAN_STATE/theme/btop.theme" "$btop_dir/themes/handaan.theme"
        echo "  linked btop's theme"
    fi

    if [[ -e $btop_dir/btop.conf ]]; then
        grep -q '^color_theme = "handaan"' "$btop_dir/btop.conf" \
            || echo "  ~/.config/btop/btop.conf is yours; set color_theme = \"handaan\" in it to use the wallpaper's colours"
    else
        cp "$HANDAAN_PATH/config/btop/btop.conf" "$btop_dir/btop.conf"
        echo "  seeded ~/.config/btop/btop.conf with the handaan theme"
    fi
fi

cat <<'HINT'
  kitty: add to kitty.conf, then open a new kitty
    include ~/.local/state/handaan/theme/kitty.conf
  Neovim: add to your config
    vim.opt.rtp:append((vim.env.HANDAAN_PATH or vim.env.HOME .. "/.local/share/handaan") .. "/default/nvim")
    vim.cmd.colorscheme("handaan")
HINT
