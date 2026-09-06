#!/bin/bash
log_info "Configuring Zsh..."
sudo chsh -s /bin/zsh "$USER"


# The seeded entry points are deliberately tiny. The body lives in the checkout
# so a `git pull` updates it; these two files exist only to point at it and to
# give you somewhere of your own to add to. Neither is overwritten on a rerun.
#
# These are written BEFORE Oh My Zsh is installed, and the installer is then
# given --keep-zshrc. Its default behaviour is to write its own ~/.zshrc from a
# template, which on a fresh machine silently wins the `[[ ! -f ]]` guard below
# and leaves the user with the stock Oh My Zsh config instead of handaan's --
# PATH and $HANDAAN_PATH still work, because those come from ~/.zshenv, so
# nothing looks broken until an alias or mise activation is missing.
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

# Installed after the seeds, and told to keep them. Without --keep-zshrc the
# installer backs up whatever is there and writes its own template.
if [[ ! -d $HOME/.oh-my-zsh ]]; then
    log_info "Installing Oh My Zsh..."
    installer=$(mktemp -t oh-my-zsh.XXXXXX.sh)
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
    sh "$installer" --unattended --keep-zshrc
    rm -f "$installer"
else
    log_info "Oh My Zsh is already installed"
fi
