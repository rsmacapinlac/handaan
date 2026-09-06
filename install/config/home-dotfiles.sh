#!/bin/bash
# Seed the root dotfiles handaan still owns.
#
# The shell is not among them. handaan installs no shell, chooses no login
# shell, and seeds neither ~/.zshrc nor ~/.zshenv -- see
# docs/decisions/adrs/0006-leave-the-login-shell-to-the-user.md. $HANDAAN_PATH
# and PATH reach every shell through /etc/profile.d/handaan.sh and
# ~/.config/uwsm/env instead, both written by env-bootstrap.sh.
#
# Copied, not linked, and only when absent: these are yours once they land.

log_info "Seeding root dotfiles..."

for pair in "vimrc:.vimrc" "vimrc.bundles:.vimrc.bundles" "face:.face"; do
    src=${pair%%:*}; dest=${pair##*:}
    [[ -e $HOME/$dest ]] || cp "$HANDAAN_PATH/default/$src" "$HOME/$dest"
done

log_success "Root dotfiles seeded"
