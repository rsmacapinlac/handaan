#!/usr/bin/env bash
# Every wallpaper handaan ships carries a credit whose licence allows it to be
# redistributed, and every credit belongs to a wallpaper.
#
# default/wallpapers is published with the repository, so an image there is
# handed to everyone who clones it. The rules, and why each licence is or is
# not accepted, are in default/wallpapers/README.md. Your own wallpapers under
# ~/.config/handaan/wallpapers are never checked: nothing there is published.
#
# Usage:
#   test/wallpaper-credits.sh              # the tree this script lives in
#   test/wallpaper-credits.sh <directory>  # any other wallpaper folder

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root="${1:-$SCRIPT_DIR/../default/wallpapers}"

readonly ACCEPTED="CC0-1.0 public-domain CC-BY-2.0 CC-BY-3.0 CC-BY-4.0 CC-BY-SA-2.0 CC-BY-SA-3.0 CC-BY-SA-4.0"

failures=0
fail() {
    echo "FAIL ${1#"$root"/}: $2" >&2
    failures=$((failures + 1))
}

# The value of one field in a sidecar, or empty.
field() {
    sed -nE "s/^[[:space:]]*$2[[:space:]]*:[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p" "$1" | head -n 1
}

images=0
while IFS= read -r -d '' image; do
    images=$((images + 1))
    credit="$image.credit"
    if [[ ! -f $credit ]]; then
        fail "$image" "no credit (expected ${credit##*/})"
        continue
    fi
    for key in artist source license; do
        [[ -n $(field "$credit" "$key") ]] || fail "$credit" "no $key"
    done
    license="$(field "$credit" license)"
    if [[ -n $license && " $ACCEPTED " != *" $license "* ]]; then
        fail "$credit" "license '$license' is not one that allows redistribution (accepted: $ACCEPTED)"
    fi
done < <(find -L "$root" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)

while IFS= read -r -d '' credit; do
    [[ -f ${credit%.credit} ]] || fail "$credit" "credits an image that is not there"
done < <(find -L "$root" -type f -name '*.credit' -print0)

if (( failures > 0 )); then
    echo "$failures problem(s) across $images wallpaper(s) in $root" >&2
    exit 1
fi
echo "ok: $images wallpaper(s), all credited"
