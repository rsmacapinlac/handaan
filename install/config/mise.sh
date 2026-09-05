#!/bin/bash
log_info "Installing Mise-backed tool launchers..."
export PATH="$HOME/.local/bin:$PATH"
"$HANDAAN_PATH/bin/handaan-mise-tools"
