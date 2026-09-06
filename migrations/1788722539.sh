echo "Hand the zsh configuration over: handaan no longer owns your login shell"

# handaan used to install zsh, run `chsh -s /bin/zsh`, install Oh My Zsh, and
# seed ~/.zshrc and ~/.zshenv as stubs sourcing default/zsh/{rc,aliases,env}
# out of the checkout. That whole tree is gone -- the login shell is a
# preference, not desktop chrome, so it belongs to the user's own dotfile
# repository now. See docs/decisions/adrs/0006-leave-the-login-shell-to-the-user.md.
#
# The seeded stubs are still on this machine and still point at the removed
# files, so every new shell prints "no such file or directory" and comes up
# without the prompt, the aliases or mise activation. This copies the body out
# of the checkout -- from git history, since `git pull` already deleted it --
# into ~/.zsh/, which is yours, and repoints the stubs at it. Nothing is lost
# and nothing further reaches back into $HANDAAN_PATH for shell configuration.
#
# Idempotent: a ~/.zshrc that no longer names default/zsh is left alone, and so
# is one that another dotfile manager has symlinked into its own checkout --
# writing through that symlink would edit the source repository, not this
# machine.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"

# Recover a file handaan used to ship, from wherever it still exists:
#
#   the worktree   if this runs before the pull that removes the file
#   HEAD           if the worktree copy was deleted by hand but not committed
#   history        the normal case -- the parent of the commit that deleted it,
#                  which `rev-list -1 HEAD -- <path>` names
recover() {
    local path=$1 last

    if [[ -f $HANDAAN_PATH/$path ]]; then
        cat "$HANDAAN_PATH/$path"
        return 0
    fi

    if git -C "$HANDAAN_PATH" cat-file -e "HEAD:$path" 2>/dev/null; then
        git -C "$HANDAAN_PATH" show "HEAD:$path"
        return $?
    fi

    last=$(git -C "$HANDAAN_PATH" rev-list -1 HEAD -- "$path" 2>/dev/null)
    [[ -n $last ]] || return 1
    git -C "$HANDAAN_PATH" show "$last^:$path" 2>/dev/null
}

needs_handover() {
    local file=$1
    [[ -f $file ]] || return 1
    [[ -L $file ]] && return 1
    grep -q 'default/zsh/' "$file"
}

if ! needs_handover "$HOME/.zshrc" && ! needs_handover "$HOME/.zshenv"; then
    echo "  no handaan-seeded zsh stub left to hand over; nothing to do"
    exit 0
fi

mkdir -p "$HOME/.zsh"

for part in rc aliases env; do
    [[ -f $HOME/.zsh/$part ]] && continue
    if ! recover "default/zsh/$part" > "$HOME/.zsh/$part"; then
        rm -f "$HOME/.zsh/$part"
        echo "  could not recover default/zsh/$part from the checkout or its history" >&2
        echo "  leaving ~/.zshrc and ~/.zshenv untouched so nothing is lost" >&2
        exit 1
    fi
    echo "  wrote ~/.zsh/$part"
done

# Two things in the recovered body are no longer true of it. It sourced the
# aliases back out of $HANDAAN_PATH, and that path is gone; and its header told
# you not to edit it, because handaan replaced it on every pull. Both were
# properties of living in the checkout, and it does not any more.
sed -i 's#^source "${HANDAAN_PATH:-$HOME/.local/share/handaan}/default/zsh/aliases"$#source "$HOME/.zsh/aliases"#' \
    "$HOME/.zsh/rc"

sed -i "1,2c\\
# Yours. This was handaan's default/zsh/rc, copied here when handaan stopped\\
# owning the login shell -- edit it freely, nothing overwrites it now." \
    "$HOME/.zsh/rc"

if needs_handover "$HOME/.zshrc"; then
    cp -f "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
    cat > "$HOME/.zshrc" <<'ZSHRC'
# Yours. handaan no longer seeds or reads this file.
#
# The body was handaan's until the login shell moved out of it; it now lives in
# ~/.zsh/rc, which is a plain copy you are free to edit. ~/.zshrc.local still
# loads last, so anything already in it keeps working.
[[ -f ~/.zsh/rc ]] && . ~/.zsh/rc
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local
ZSHRC
    echo "  repointed ~/.zshrc at ~/.zsh/rc (previous file kept as a .bak)"
fi

if needs_handover "$HOME/.zshenv"; then
    cp -f "$HOME/.zshenv" "$HOME/.zshenv.bak.$(date +%s)"
    cat > "$HOME/.zshenv" <<'ZSHENV'
# Yours. handaan no longer seeds this file.
#
# env-bootstrap is still handaan's and is still sourced here: it is what puts
# $HANDAAN_PATH and its bin/ on PATH for a non-login interactive zsh, which
# /etc/profile.d/handaan.sh does not reach. Without it `handaan-*` is "command
# not found" in a new terminal. The zsh-specific half moved to ~/.zsh/env.
. "$HOME/.local/share/handaan/default/shell/env-bootstrap"
[[ -f ~/.zsh/env ]] && . ~/.zsh/env
[[ -f ~/.zshenv.local ]] && . ~/.zshenv.local
ZSHENV
    echo "  repointed ~/.zshenv at ~/.zsh/env (previous file kept as a .bak)"
fi

echo "  zsh is yours now -- handaan will not write these files again"
