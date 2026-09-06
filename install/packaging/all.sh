#!/bin/bash
run_phase "$HANDAAN_INSTALL/packaging/aur.sh"
run_phase "$HANDAAN_INSTALL/packaging/base.sh"
run_phase "$HANDAAN_INSTALL/packaging/hardware.sh"
run_phase "$HANDAAN_INSTALL/packaging/browsers.sh"
run_phase "$HANDAAN_INSTALL/packaging/security.sh"
run_phase "$HANDAAN_INSTALL/packaging/desktop.sh"
run_phase "$HANDAAN_INSTALL/packaging/fonts.sh"
run_phase "$HANDAAN_INSTALL/packaging/file-managers.sh"
