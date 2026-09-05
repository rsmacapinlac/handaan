#!/bin/bash
# handaan installer.
#
# Runs from the checkout at $HANDAAN_PATH. boot.sh clones the tree and then
# sources this file; it can also be run directly from an existing checkout.
#
# Every phase is a small script doing one thing, grouped into directories by
# when it has to happen. Adding a step means adding a file and one line to the
# relevant all.sh -- never growing a function in here.

set -eEo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=default/zsh/env-bootstrap
source "$SCRIPT_DIR/default/zsh/env-bootstrap"
HANDAAN_PATH="$SCRIPT_DIR"
export HANDAAN_PATH
export HANDAAN_INSTALL="$HANDAAN_PATH/install"

# shellcheck source=install/lib/handaan-common.sh
source "$HANDAAN_INSTALL/lib/handaan-common.sh"

# Each phase runs in a subshell so a failure stops that phase and is reported
# here, rather than leaving the installer half-applied with no indication which
# step went wrong. Sourcing (not executing) means phases inherit the log helpers
# and can `return` early without spawning another bash.
run_phase() {
    local script=$1
    log_info "▸ ${script#"$HANDAAN_PATH"/}"
    if ! ( set -euo pipefail; source "$script" ); then
        log_error "Phase failed: ${script#"$HANDAAN_PATH"/}"
        return 1
    fi
}

main() {
    log_info "Installing handaan $(cat "$HANDAAN_PATH/version") from $HANDAAN_PATH"
    begin_handaan_install

    source "$HANDAAN_INSTALL/preflight/all.sh"
    source "$HANDAAN_INSTALL/packaging/all.sh"
    source "$HANDAAN_INSTALL/config/all.sh"
    source "$HANDAAN_INSTALL/login/all.sh"
    source "$HANDAAN_INSTALL/post-install/all.sh"
}

main "$@"
