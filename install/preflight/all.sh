#!/bin/bash
run_phase "$HANDAAN_INSTALL/preflight/guard.sh"
run_phase "$HANDAAN_INSTALL/preflight/pacman.sh"
run_phase "$HANDAAN_INSTALL/preflight/mirrors.sh"
run_phase "$HANDAAN_INSTALL/preflight/migrations.sh"
