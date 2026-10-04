echo "Point the Todoist launcher at the window Chromium actually opens"

# bin/handaan-service-todoist wrote StartupWMClass=todoist and launched with
# --class=todoist, on the belief that the flag pins the window's identity. It
# does not on Wayland: Chromium ignores --class there and reports an app id it
# builds from the URL, chrome-app.todoist.com__app_-Default. Nothing could tie
# the window back to its launcher, so the island named it "Com__app_-Default".
#
# The script now writes the real id and drops the flag; rerunning it is the
# fresh path. This rewrites a launcher it already wrote, without the network
# fetch a full rerun would need for the icon.
#
# Idempotent: a machine that never ran the script has no launcher to fix, and
# one already fixed is left alone.

desktop="$HOME/.local/share/applications/todoist.desktop"
app_id="chrome-app.todoist.com__app_-Default"

if [[ ! -f $desktop ]]; then
    echo "  Todoist was never installed here; nothing to do"
    exit 0
fi

if grep -qx "StartupWMClass=$app_id" "$desktop"; then
    echo "  already points at $app_id; nothing to do"
    exit 0
fi

sed -i -E \
    -e "s/^StartupWMClass=.*/StartupWMClass=$app_id/" \
    -e 's/^(Exec=chromium --app=[^ ]+) --class=[^ ]+/\1/' \
    "$desktop"

command -v update-desktop-database &>/dev/null &&
    update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true

echo "  $desktop now names $app_id"
