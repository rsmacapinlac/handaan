#!/usr/bin/env bash
# Seed a throwaway app under ~/.config/handaan/apps/, so a VM rehearsal has
# something real for handaan-apps and handaan-update to exercise.
#
# Every real app normally comes from a user's own dotfile repository (see
# docs/decisions/adrs/0005-accept-user-owned-optional-applications.md), which
# a fresh VM has no access to -- without this, there is nothing to discover
# and no way to rehearse packages/install.sh/update.sh/config/ at all.
#
# This is meant for a disposable VM: it writes into the real apps root, on
# the assumption that the whole machine gets thrown away afterward. Don't run
# it on a machine you intend to keep using.
#
# cowsay is the package: tiny, in the official repos (no AUR build wait), and
# trivial to verify by hand.
#
# Usage:
#   test/seed-handaan-test-app.sh          # seed it
#   test/seed-handaan-test-app.sh --remove # tear it down

set -euo pipefail

APP_DIR="$HOME/.config/handaan/apps/handaan-test"

if [[ ${1:-} == --remove ]]; then
    rm -rf "$APP_DIR"
    rm -rf "$HOME/.local/state/handaan-test" "$HOME/.local/share/handaan-test"
    echo "Removed $APP_DIR"
    exit 0
fi

mkdir -p "$APP_DIR/config/.local/share/handaan-test"

cat >"$APP_DIR/meta" <<'EOF'
# handaan:summary=Test app for exercising handaan-apps -- safe to remove.
EOF

cat >"$APP_DIR/packages" <<'EOF'
cowsay
EOF

cat >"$APP_DIR/install.sh" <<'EOF'
mkdir -p "$HOME/.local/state/handaan-test"
date >"$HOME/.local/state/handaan-test/install-ran"
log_info "handaan-test install.sh ran"
EOF

cat >"$APP_DIR/update.sh" <<'EOF'
mkdir -p "$HOME/.local/state/handaan-test"
date >"$HOME/.local/state/handaan-test/update-ran"
log_info "handaan-test update.sh ran"
EOF

cat >"$APP_DIR/config/.local/share/handaan-test/from-config" <<'EOF'
Seeded by config/ -- proves the no-clobber copy into $HOME ran.
EOF

echo "Seeded $APP_DIR"
cat <<'EOF'

Verify with:
  handaan apps-install handaan-test  # exercises packages + install.sh + config/
  command -v cowsay && cowsay moo
  cat ~/.local/state/handaan-test/install-ran
  cat ~/.local/share/handaan-test/from-config

  handaan-update                     # exercises update.sh on its own
  cat ~/.local/state/handaan-test/update-ran

Tear down with: test/seed-handaan-test-app.sh --remove
EOF
