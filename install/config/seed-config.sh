#!/bin/bash
# Seed ~/.config from the handaan defaults.
#
# This is the copy model: files land in ~/.config once and are yours from then
# on. An update never touches them -- take a newer default deliberately with
# `handaan-refresh-config`, and see what has drifted with `handaan-diff-config`.
#
# --no-clobber is what makes this rerunnable. A second run fills in what is
# missing and leaves every existing file alone, so a failed bootstrap can be
# retried without losing edits made between the attempts.

log_info "Seeding ~/.config from handaan defaults..."
mkdir -p "$HOME/.config"

# A machine migrating off an rcm-managed tree still has symlinks pointing into
# the old checkout. `cp` follows a symlink and writes through it, which would
# silently overwrite the *source* repository instead of seeding this machine.
# Break them first, and say which ones, because a broken link is a change the
# user needs to know about.
broken=0
while IFS= read -r -d '' link; do
    target=$(readlink -f "$link" 2>/dev/null || true)
    case "$target" in
        "$HOME"/workspace/*|"$HANDAAN_PATH"/*)
            rm -f "$link"
            broken=$((broken + 1))
            ;;
    esac
done < <(find "$HOME/.config" -maxdepth 3 -type l -print0 2>/dev/null)
(( broken == 0 )) || log_warning "Removed $broken symlink(s) left by a previous dotfile manager"

cp -Rn "$HANDAAN_PATH"/config/. "$HOME/.config/" 2>/dev/null || true

# Units are read by systemd from ~/.config/systemd/user, so they are copied
# rather than read in place. Their ExecStart points back at $HANDAAN_PATH.
mkdir -p "$HOME/.config/systemd/user"
cp -f "$HANDAAN_PATH"/default/systemd/user/*.service "$HOME/.config/systemd/user/"

# Overrides for core packages only. applications/optional/ holds overrides for
# packages handaan-apps installs, and is seeded from there instead -- copying
# it here would drop a launcher for a package that isn't installed yet.
mkdir -p "$HOME/.local/share/applications"
for entry in "$HANDAAN_PATH"/applications/*.desktop; do
    [[ -e $entry ]] || continue
    cp -n "$entry" "$HOME/.local/share/applications/"
done

log_success "~/.config seeded"
