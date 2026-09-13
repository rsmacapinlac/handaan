echo "Remove ~/.config/waybar if every file in it is one handaan shipped"

# Waybar is uninstalled (1789324024), and nothing reads ~/.config/waybar any
# more. A migration does not delete what the user owns, but a file byte-for-byte
# identical to one handaan seeded was never edited -- it is handaan's leftover,
# not the user's, and leaving it behind is just clutter handaan made.
#
# So each file is checked against every version handaan ever shipped at the
# same path under config/waybar/, taken from the checkout's own git history.
# Only when all of them match is the directory removed. Anything else -- a file
# that was edited, a file handaan never shipped, a symlink from a dotfile
# repository deploying by link -- means someone put it there, and the whole
# directory is left alone with the reason printed.
#
# Idempotent: once the directory is gone there is nothing to check.

: "${HANDAAN_PATH:=$HOME/.local/share/handaan}"

dir="$HOME/.config/waybar"

if [[ ! -e $dir && ! -L $dir ]]; then
    echo "  no ~/.config/waybar; nothing to remove"
    exit 0
fi

if [[ -L $dir || ! -d $dir ]]; then
    echo "  ~/.config/waybar is not a plain directory, so another tree owns it; left in place"
    exit 0
fi

# A shallow clone has no history to compare against, and "could not tell" must
# never read as "handaan's".
if [[ $(git -C "$HANDAAN_PATH" rev-parse --is-shallow-repository) != false ]]; then
    echo "  $HANDAAN_PATH has no full git history to compare against; left in place"
    exit 0
fi

# Every blob handaan ever shipped, keyed by its path relative to config/waybar/.
declare -A shipped=()
while read -r commit; do
    while IFS=$'\t' read -r meta path; do
        shipped["${path#config/waybar/}:${meta##* }"]=1
    done < <(git -C "$HANDAAN_PATH" -c core.quotePath=false ls-tree -r "$commit" -- config/waybar/)
done < <(git -C "$HANDAAN_PATH" rev-list HEAD -- config/waybar/)

if (( ${#shipped[@]} == 0 )); then
    echo "  no history of config/waybar/ in $HANDAAN_PATH; left in place"
    exit 0
fi

foreign=()
while IFS= read -r -d '' entry; do
    rel=${entry#"$dir"/}
    if [[ -L $entry || ! -f $entry ]]; then
        foreign+=("$rel (not a regular file)")
        continue
    fi
    blob=$(git hash-object --no-filters -- "$entry")
    if [[ -z ${shipped["$rel:$blob"]:-} ]]; then
        foreign+=("$rel")
    fi
done < <(find "$dir" -mindepth 1 ! -type d -print0)

if (( ${#foreign[@]} > 0 )); then
    echo "  ~/.config/waybar holds files handaan did not ship, so it was left in place:"
    printf '    %s\n' "${foreign[@]}"
    echo "  Nothing reads it now. Remove it yourself when you are done with it:"
    echo "    rm -r ~/.config/waybar"
    exit 0
fi

rm -r "$dir"
echo "  removed ~/.config/waybar -- every file in it was one handaan shipped, unedited"
