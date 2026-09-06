#!/bin/bash
tpm_dir="$HOME/.config/tmux/plugins/tpm"

if [[ ! -d $tpm_dir ]]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
fi

# tmux.conf itself comes from the private companion tree, not handaan, so a
# handaan-only machine has no plugin list to read yet. TPM is cloned above
# regardless -- installing plugins is just deferred until tmux.conf exists.
if [[ ! -f $HOME/.config/tmux/tmux.conf ]]; then
    log_warning "No ~/.config/tmux/tmux.conf yet; skipping plugin install"
    return 0 2>/dev/null || exit 0
fi

# Cloning TPM only installs the plugin manager. Without the step below the
# plugins declared in tmux.conf -- Catppuccin included -- are never fetched,
# and tmux comes up unstyled until someone presses prefix + I by hand.
[[ -x $tpm_dir/bin/install_plugins ]] || return 0 2>/dev/null || exit 0

# install_plugins reads the plugin list from tmux options, so a server has to
# exist and have sourced the config first. On a fresh box there is no server.
tmux start-server 2>/dev/null || true
tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true

if "$tpm_dir/bin/install_plugins"; then
    log_success "tmux plugins installed"
else
    log_warning "tmux plugin install failed; run prefix + I inside tmux"
fi
