#!/bin/bash
run_phase "$HANDAAN_INSTALL/config/home-dotfiles.sh"
run_phase "$HANDAAN_INSTALL/config/env-bootstrap.sh"
run_phase "$HANDAAN_INSTALL/config/seed-config.sh"
run_phase "$HANDAAN_INSTALL/config/locale.sh"
run_phase "$HANDAAN_INSTALL/config/gpg.sh"
run_phase "$HANDAAN_INSTALL/config/mise.sh"
run_phase "$HANDAAN_INSTALL/config/tmux.sh"
run_phase "$HANDAAN_INSTALL/config/timeshift.sh"
