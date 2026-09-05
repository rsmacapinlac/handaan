#!/bin/bash
log_info "Installing core credential tools..."
yay_install_list "$HANDAAN_INSTALL/security.packages"

if [[ ! -f $HOME/.mozilla/native-messaging-hosts/passff.json ]]; then
    curl -fsSL \
        https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh \
        | bash -s -- firefox
fi
