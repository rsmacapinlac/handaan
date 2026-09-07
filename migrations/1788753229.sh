echo "Record which optional apps are already installed, for the new per-app marker"

# handaan-apps used to infer "installed" from an app's package list alone, and
# that was wrong in both directions. An app that installs from inside its own
# install.sh declares no packages, so it could never report installed and sat in
# --pending for good. An app whose payload is a config/ tree reported installed
# the moment anything else pulled in the one package it named, so it was never
# selected, its files were never copied, and the thing it exists to deliver
# never arrived. The answer is now a marker under $HANDAAN_STATE/apps/, written
# when handaan actually installs the app.
#
# A fresh install needs nothing from this. It has no apps installed, so no
# markers is already the correct answer, and handaan-apps writes them from then
# on. This exists only for a machine that installed apps before the marker did,
# where every app it already has would otherwise report pending at once.
#
# The backfill deliberately reproduces the OLD answer rather than a better one:
# an app is marked when it declares packages and all of them are installed.
# That is exactly what the picker showed before this change, so nothing that was
# ticked yesterday comes back unticked. Apps declaring no packages stay unmarked
# because nothing here can know -- see the note printed at the end.
#
# The cost of reproducing the old answer is that it reproduces the old mistake
# too: an app that only ever *looked* installed, because something else pulled
# in the one package it named, is recorded as installed. Nothing here can tell
# that apart from a real install. `--unmark` then a real install fixes one.

: "${HANDAAN_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/handaan}"

apps_root="$HOME/.config/handaan/apps"
apps_state="$HANDAAN_STATE/apps"

if [[ ! -d $apps_root ]]; then
    echo "  no apps directory; nothing to record"
    exit 0
fi

mkdir -p "$apps_state"

# One `pacman -Qq` for the whole sweep, as handaan-apps does for the picker.
declare -A installed_pkgs=()
while read -r pkg; do
    installed_pkgs[$pkg]=1
done < <(pacman -Qq 2>/dev/null)

marked=0
unknown=()
for dir in "$apps_root"/*/; do
    [[ -d $dir ]] || continue
    name=$(basename "$dir")

    # Idempotent: an app already recorded is left exactly as it is.
    [[ -f "$apps_state/$name" ]] && continue

    if [[ ! -f "${dir}packages" ]]; then
        unknown+=("$name")
        continue
    fi

    declared=0
    complete=1
    while read -r pkg; do
        [[ -n $pkg ]] || continue
        declared=1
        if [[ -z ${installed_pkgs[$pkg]:-} ]]; then
            complete=0
            break
        fi
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "${dir}packages")

    if (( declared && complete )); then
        touch "$apps_state/$name"
        marked=$((marked + 1))
    fi
done

echo "  recorded $marked app(s) as already installed, by the old packages-only rule"
if (( marked > 0 )); then
    echo "  If one of them was never really deployed: handaan apps --unmark <name>"
fi

if (( ${#unknown[@]} > 0 )); then
    echo
    echo "  These declare no packages, so nothing here can tell whether they are"
    echo "  installed, and they will keep showing as pending:"
    printf '    %s\n' "${unknown[@]}"
    echo
    echo "  If one is in fact installed, record it without reinstalling:"
    echo "    handaan apps --mark ${unknown[*]}"
fi
