echo "Restore handaan's ~/.zshrc where the Oh My Zsh template overwrote it"

# install/config/shell.sh used to install Oh My Zsh before seeding ~/.zshrc.
# The Oh My Zsh installer writes its own ~/.zshrc from a template, so on a
# fresh machine the seed's `[[ ! -f ]]` guard was already false and handaan's
# entry point was never written. ~/.zshenv was seeded correctly either way, so
# $HANDAAN_PATH and PATH both work and nothing looks wrong until an alias,
# the prompt, or mise activation turns out to be missing.
#
# Idempotent: a ~/.zshrc that already sources handaan's body is left alone.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"
zshrc="$HOME/.zshrc"

if [[ -f $zshrc ]] && grep -q 'default/zsh/rc' "$zshrc"; then
    echo "  ~/.zshrc already sources handaan's body; nothing to do"
    exit 0
fi

if [[ -f $zshrc ]]; then
    backup="$zshrc.bak.$(date +%s)"
    cp -f "$zshrc" "$backup"
    echo "  saved the existing ~/.zshrc as $backup"
fi

cat > "$zshrc" <<'ZSHRC'
# Seeded by handaan. Yours -- an update will not overwrite it.
#
# The body is read live from the checkout, so handaan improvements arrive with
# a `git pull`. Put anything of your own in ~/.zshrc.local, which loads last.
. "${HANDAAN_PATH:-$HOME/.local/share/handaan}/default/zsh/rc"
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local
ZSHRC

echo "  wrote handaan's ~/.zshrc"
