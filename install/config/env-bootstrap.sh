#!/bin/bash
# Wire env-bootstrap into every entry point handaan owns.
#
# These two are the whole of it. handaan installs no shell and seeds no shell
# rc file, so a login shell gets $HANDAAN_PATH from /etc/profile.d
# and the graphical session gets it from uwsm, which inherits no interactive
# PATH at all; see docs/hyprland-startup.md. A non-login interactive shell
# reads neither, which is why a user-supplied ~/.zshenv (or bashrc) still has
# to source env-bootstrap itself.

log_info "Wiring env-bootstrap into login shells and the session..."

# Guarded on the file existing so this is harmless for any other account on the
# machine, which will not have a handaan checkout.
sudo tee /etc/profile.d/handaan.sh >/dev/null <<'PROFILE'
# handaan: put $HANDAAN_PATH and its bin/ on PATH for every login shell.
# Written by install/config/env-bootstrap.sh -- edit the source, not this file.
if [ -r "$HOME/.local/share/handaan/default/shell/env-bootstrap" ]; then
    . "$HOME/.local/share/handaan/default/shell/env-bootstrap"
fi
PROFILE
sudo chmod 644 /etc/profile.d/handaan.sh
log_success "Wrote /etc/profile.d/handaan.sh"

mkdir -p "$HOME/.config/uwsm"
if [[ ! -f $HOME/.config/uwsm/env ]]; then
    cat > "$HOME/.config/uwsm/env" <<'UWSM'
# Seeded by handaan. Yours -- an update will not overwrite it.
# uwsm inherits no interactive shell PATH, so the session gets it here.
. "$HOME/.local/share/handaan/default/shell/env-bootstrap"
UWSM
    log_success "Seeded ~/.config/uwsm/env"
fi
