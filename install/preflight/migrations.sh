#!/bin/bash
# Mark every shipped migration as already applied.
#
# A machine built from this checkout already has everything the migrations were
# written to repair, so replaying them would at best waste time and at worst
# undo something the current installer does correctly. Migrations exist for
# machines installed *before* a change landed -- see bin/handaan-migrate.

state_dir="$HANDAAN_STATE/migrations"
mkdir -p "$state_dir/skipped"

count=0
for file in "$HANDAAN_PATH"/migrations/*.sh; do
    [[ -e $file ]] || continue
    touch "$state_dir/$(basename "$file")"
    count=$((count + 1))
done
log_info "Marked $count migration(s) as applied for this fresh install"
