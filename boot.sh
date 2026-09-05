#!/bin/bash
# Dispatcher for the two-stage handaan bootstrap.
#
# Run the same command on the live ISO and after the first reboot:
#   curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash
#
# Unlike a plain script fetch, the installed-system phase clones the whole tree
# to $HANDAAN_PATH and runs from there. The checkout is not a build artifact --
# it is where handaan lives afterwards, and every path in the installed system
# resolves back into it.

set -euo pipefail

HANDAAN_REPO="${HANDAAN_REPO:-rsmacapinlac/handaan}"
export HANDAAN_REPO
export HANDAAN_REF="${HANDAAN_REF:-main}"
HANDAAN_PATH="${HANDAAN_PATH:-$HOME/.local/share/handaan}"
export HANDAAN_PATH
RAW_BASE="https://raw.githubusercontent.com/${HANDAAN_REPO}/${HANDAAN_REF}"
ARCHINSTALL_URL="${ARCHINSTALL_URL:-${RAW_BASE}/install/archinstall/install.sh}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

on_archiso() {
    [[ ${HANDAAN_FORCE_PHASE:-} == iso ]] && return 0
    [[ ${HANDAAN_FORCE_PHASE:-} == system ]] && return 1
    [[ -d /run/archiso ]] && return 0
    [[ $(cat /etc/hostname 2>/dev/null) == archiso ]]
}

check_internet() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 github.com &>/dev/null; then
        log_error "No internet connection."
        log_error "Connect first: iwctl on the live ISO, nmcli on the installed system."
        exit 1
    fi
}

# Piping this script to bash makes stdin the pipe, so a prompt downstream would
# read the script's own remaining text or fail outright. Reopen the terminal.
run_with_terminal() {
    if [[ -t 0 ]]; then
        "$@"
    elif ( : < /dev/tty ) 2>/dev/null; then
        "$@" < /dev/tty
    else
        log_warning "No controlling terminal is available; prompts may fail."
        "$@"
    fi
}

# A truncated fetch is otherwise indistinguishable from an empty script that
# runs and succeeds, so a zero-byte result is a failure here.
download() {
    local url=$1 destination=$2
    if ! curl -fsSL "$url" -o "$destination"; then
        log_error "Failed to download $url"
        exit 1
    fi
    if [[ ! -s $destination ]]; then
        log_error "Downloaded an empty file from $url"
        exit 1
    fi
}

run_archinstall_phase() {
    if [[ $EUID -ne 0 ]]; then
        log_error "The live-ISO phase must run as root."
        exit 1
    fi

    local temp_dir script status=0
    temp_dir=$(mktemp -d -t handaan-archinstall.XXXXXX)
    script="$temp_dir/install.sh"

    download "$ARCHINSTALL_URL" "$script"
    chmod +x "$script"
    export RAW_BASE
    export API_BASE="https://api.github.com/repos/${HANDAAN_REPO}/contents/install/archinstall"
    run_with_terminal bash "$script" || status=$?
    rm -rf "$temp_dir"
    (( status == 0 )) || exit "$status"
}

clone_or_update_checkout() {
    if [[ -d $HANDAAN_PATH/.git ]]; then
        # Never destroy an existing checkout: on a rerun it may hold work that
        # is not pushed. Omarchy can `rm -rf` here because its tree is only ever
        # written by an install; this one is also where handaan is developed.
        log_info "handaan is already checked out at $HANDAAN_PATH; leaving it untouched"
        return 0
    fi

    if [[ -e $HANDAAN_PATH ]]; then
        log_error "$HANDAAN_PATH exists but is not a git checkout. Move it aside and rerun."
        exit 1
    fi

    log_info "Cloning handaan into $HANDAAN_PATH..."
    sudo pacman -S --needed --noconfirm git
    mkdir -p "$(dirname "$HANDAAN_PATH")"
    git clone --branch "$HANDAAN_REF" \
        "https://github.com/${HANDAAN_REPO}.git" "$HANDAAN_PATH"
    git -C "$HANDAAN_PATH" remote set-url --push origin \
        "git@github.com:${HANDAAN_REPO}.git"
    log_success "Cloned handaan@${HANDAAN_REF}"
}

run_install_phase() {
    if [[ $EUID -eq 0 ]]; then
        log_error "The installed-system phase must run as a regular user."
        exit 1
    fi
    if ! command -v sudo &>/dev/null; then
        log_error "sudo is not installed. Install it and add the user to wheel."
        exit 1
    fi
    sudo -v

    clone_or_update_checkout

    local status=0
    run_with_terminal bash "$HANDAAN_PATH/install.sh" || status=$?
    if (( status != 0 )); then
        log_error "handaan install failed with exit $status."
        log_error "The checkout is at $HANDAAN_PATH; fix and rerun bash install.sh."
        exit "$status"
    fi
}

main() {
    log_info "handaan bootstrap (${HANDAAN_REPO}@${HANDAAN_REF})"
    check_internet
    if on_archiso; then
        run_archinstall_phase
    else
        run_install_phase
    fi
}

main "$@"
