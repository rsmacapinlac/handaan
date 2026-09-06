echo "Wire env-bootstrap into login shells and the graphical session"

# handaan used to source default/shell/env-bootstrap from ~/.zshenv only. zsh is
# the login shell, so that looked right -- but a bash login, an ssh command, or a
# TTY opened before `chsh` took effect all came up without $HANDAAN_PATH/bin on
# PATH, and uwsm (which inherits no interactive PATH at all) never had it.
#
# Idempotent: both files are rewritten only when they are missing or stale.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"

# The file moved out of default/zsh/ when it stopped being zsh-specific. A
# checkout that has already been pulled forward has it in the new place; bail
# out rather than wiring a path that does not exist.
if [[ ! -r $HANDAAN_PATH/default/shell/env-bootstrap ]]; then
    echo "  $HANDAAN_PATH/default/shell/env-bootstrap is missing; pull the checkout first"
    exit 1
fi

profile=/etc/profile.d/handaan.sh
if [[ -r $profile ]] && grep -q 'default/shell/env-bootstrap' "$profile"; then
    echo "  $profile already wired"
else
    sudo tee "$profile" >/dev/null <<'PROFILE'
# handaan: put $HANDAAN_PATH and its bin/ on PATH for every login shell.
# Written by install/config/env-bootstrap.sh -- edit the source, not this file.
if [ -r "$HOME/.local/share/handaan/default/shell/env-bootstrap" ]; then
    . "$HOME/.local/share/handaan/default/shell/env-bootstrap"
fi
PROFILE
    sudo chmod 644 "$profile"
    echo "  wrote $profile"
fi

uwsm_env="$HOME/.config/uwsm/env"
if [[ -f $uwsm_env ]] && grep -q 'env-bootstrap' "$uwsm_env"; then
    echo "  $uwsm_env already wired"
else
    mkdir -p "$(dirname "$uwsm_env")"
    cat > "$uwsm_env" <<'UWSM'
# Seeded by handaan. Yours -- an update will not overwrite it.
# uwsm inherits no interactive shell PATH, so the session gets it here.
. "$HOME/.local/share/handaan/default/shell/env-bootstrap"
UWSM
    echo "  wrote $uwsm_env"
fi

# ~/.zshenv points at the old default/zsh/ path on machines installed before
# the move, which would break every new shell once the checkout moves forward.
if [[ -f $HOME/.zshenv ]] && grep -q 'default/zsh/env-bootstrap' "$HOME/.zshenv"; then
    sed -i 's#default/zsh/env-bootstrap#default/shell/env-bootstrap#' "$HOME/.zshenv"
    echo "  repointed ~/.zshenv at default/shell/env-bootstrap"
fi
