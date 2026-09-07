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

# Seeded one file at a time rather than `cp -Rn config/. ~/.config/`, and this
# is the whole reason why.
#
# The hazard `cp -R` carries is a symlinked *directory* at a destination path:
# cp descends through it and writes handaan's files inside whatever tree the
# link points at. --no-clobber does not help, because the files it creates in
# there are new. This used to be handled by deleting every symlink under
# ~/.config first -- `find ~/.config -maxdepth 3 -type l` -- on the theory that
# such links were leftovers from a dotfile manager the machine had migrated off.
#
# That was wrong, and destructively so. A user whose dotfile repository still
# deploys by symlink has not migrated off anything; the links are their live
# deployment. The sweep deleted all of it within its depth limit -- config
# files, an editor's init.lua, a terminal's config -- on every installer run,
# for a collision that only ever existed at the handful of paths handaan
# actually seeds.
#
# So: never delete, never descend through a link, and skip rather than write
# into a tree that is not ours. A path handaan wants that is already claimed by
# someone else's symlink is a genuine collision and is reported, not resolved.
# Nothing in ~/.config that handaan does not seed is touched at all.

# True when any component of the destination below ~/.config is a symlink.
# Writing through one would put handaan's file inside whatever it points at.
crosses_symlink() {
    local rel=$1 probe="$HOME/.config" part
    local IFS=/
    for part in $rel; do
        probe="$probe/$part"
        [[ -L $probe ]] && return 0
    done
    return 1
}

seeded=0
collided=0
while IFS= read -r -d '' src; do
    rel=${src#"$HANDAAN_PATH"/config/}
    dest="$HOME/.config/$rel"

    # -e is false for a dangling symlink, so -L is tested too: a broken link is
    # still the user's file and still theirs to fix.
    [[ -e $dest || -L $dest ]] && continue

    if crosses_symlink "$rel"; then
        log_warning "Skipping $rel: a parent under ~/.config is a symlink into another tree"
        collided=$((collided + 1))
        continue
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    seeded=$((seeded + 1))
done < <(find "$HANDAAN_PATH/config" -type f -print0)

log_info "Seeded $seeded file(s) into ~/.config"
(( collided == 0 )) || log_warning "$collided file(s) skipped; another tree already owns those paths"

# Units are read by systemd from ~/.config/systemd/user, so they are copied
# rather than read in place. Their ExecStart points back at $HANDAAN_PATH.
mkdir -p "$HOME/.config/systemd/user"
cp -f "$HANDAAN_PATH"/default/systemd/user/*.service "$HOME/.config/systemd/user/"

# Overrides for core packages only. handaan ships no optional applications of
# its own (see docs/decisions/adrs/0005-accept-user-owned-optional-applications.md),
# so anything here belongs to a package core actually installs.
mkdir -p "$HOME/.local/share/applications"
for entry in "$HANDAAN_PATH"/applications/*.desktop; do
    [[ -e $entry ]] || continue
    cp -n "$entry" "$HOME/.local/share/applications/"
done

log_success "~/.config seeded"
