#!/bin/bash
log_info "Configuring Zsh..."
sudo chsh -s /bin/zsh "$USER"

if [[ ! -d $HOME/.oh-my-zsh ]]; then
    installer=$(mktemp -t oh-my-zsh.XXXXXX.sh)
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
    sh "$installer" --unattended
    rm -f "$installer"
else
    log_info "Oh My Zsh is already installed"
fi

# The seeded entry points are deliberately tiny. The body lives in the checkout
# so a `git pull` updates it; these two files exist only to point at it and to
# give you somewhere of your own to add to. Neither is overwritten on a rerun.
if [[ ! -f $HOME/.zshenv ]]; then
    cat > "$HOME/.zshenv" <<'ZSHENV'
# Seeded by handaan. Yours -- an update will not overwrite it.
. "$HOME/.local/share/handaan/default/zsh/env-bootstrap"
. "$HANDAAN_PATH/default/zsh/env"
[[ -f ~/.zshenv.local ]] && . ~/.zshenv.local
ZSHENV
    log_success "Seeded ~/.zshenv"
fi

if [[ ! -f $HOME/.zshrc ]]; then
    cat > "$HOME/.zshrc" <<'ZSHRC'
# Seeded by handaan. Yours -- an update will not overwrite it.
#
# The body is read live from the checkout, so handaan improvements arrive with
# a `git pull`. Put anything of your own in ~/.zshrc.local, which loads last.
. "${HANDAAN_PATH:-$HOME/.local/share/handaan}/default/zsh/rc"
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local
ZSHRC
    log_success "Seeded ~/.zshrc"
fi

for pair in "vimrc:.vimrc" "vimrc.bundles:.vimrc.bundles" "face:.face"; do
    src=${pair%%:*}; dest=${pair##*:}
    [[ -e $HOME/$dest ]] || cp "$HANDAAN_PATH/default/$src" "$HOME/$dest"
done
