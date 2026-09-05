#!/bin/bash
run_phase "$HANDAAN_INSTALL/post-install/services.sh"
run_phase "$HANDAAN_INSTALL/post-install/cleanup.sh"
run_phase "$HANDAAN_INSTALL/post-install/finished.sh"
