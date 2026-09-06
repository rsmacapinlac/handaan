# 0003. Install into one owned tree, and seed the user's config from it once

Status: accepted

## Context

This configuration was previously a dotfile repository deployed by `rcm`: every tracked file became a symlink from `$HOME` back into a checkout at `~/workspace/dots`. That works, and it has one property worth keeping — an edit made on the machine lands in the repository automatically.

It also has three that stopped paying for themselves:

- **There is no such thing as a default.** Every file is *the* file. A change that should apply everywhere and a change that is true of one machine are written to the same place, so the second one dirties the working tree and eventually gets committed or lost.
- **A checkout in `~/workspace` is a work directory.** `~/workspace` is where repositories being hacked on live. The tree that rebuilds the machine is not one of those, and putting it there invites it to be treated as disposable.
- **Nothing can be applied after install.** `rcup` refreshes symlinks. It cannot enable a unit, write to `/etc`, or repoint a path an installed machine still holds, so the only way to apply anything else was to rerun the whole installer.

Omarchy solves all three the same way, and the requirement here is the same one: a single tree that owns itself, is not the user's to edit, and can be updated under a running system.

## Decision

**One tree at `$HANDAAN_PATH`, defaulting to `~/.local/share/handaan`.** The checkout is where handaan lives on an installed machine — not a build artifact, and not a copy of one. `boot.sh` clones it there and runs `install.sh` out of it; every path in the installed system resolves back into it.

**Two trees inside it, split by who may edit them:**

| tree | owner | reached how | what an update does to it |
|---|---|---|---|
| `default/` | handaan | read live from `$HANDAAN_PATH` | replaces it |
| `config/` | handaan | copied into `~/.config` once, at install | nothing |
| `~/.config/` | you | — | nothing, ever |

Hyprland shows the layering: `~/.config/hypr/hyprland.lua` puts `$HANDAAN_PATH/default` on `package.path`, requires the handaan modules as `hypr.*`, then requires your `conf.*` modules — which load last and therefore win. hyprlang has `source =` for this; Lua does not, which is why the mechanism is a `package.path` prepend rather than a copy.

**The seed is `cp -Rn`, not `cp -R`.** Refusing to clobber is what makes a second run safe: a failed bootstrap can be retried without losing edits made between the attempts.

**`$HANDAAN_PATH` is never hardcoded.** `default/shell/env-bootstrap` is the single source of truth, sourced by `/etc/profile.d/handaan.sh` (every login shell), `~/.zshenv`, `~/.config/uwsm/env` (the graphical session, which inherits no interactive `PATH`) and `install.sh`. It reads `/etc/handaan.conf` first if that file exists. Nothing writes that file today; it is the seam that makes relocating the tree — to `/usr/share/handaan` as a pacman package, say — a change to one file rather than a grep across the repository.

Wiring **only** `~/.zshenv` is not enough, and the first VM rehearsal proved it: zsh is the login shell, so everything looked correct, while a bash login, an ssh command and a TTY opened before `chsh` took effect all came up with `handaan-*` simply "command not found". The failure is silent because `~/.zshenv` is what sets `$HANDAAN_PATH` in the case anyone checks by hand.

## Consequences

**The cost is that an edit to `~/.config` no longer lands in git.** That is the deliberate trade, and it needs tooling rather than discipline, so three commands exist: `handaan-diff-config` lists what has drifted, `handaan-refresh-config` takes a newer default (with a timestamped backup and a diff), and `handaan-promote-config` sends a good local edit back into the tree. `handaan-update` reports the drift count at the end of every run, because drift that nobody is told about is drift that gets discovered during a rebuild, when it is already gone.

**`rcm` is no longer used.** The private companion repository's override mechanism, which depended entirely on `rcm` tree ordering, has since been rebuilt on the same copy model: it now seeds `~/.config` itself with the same no-clobber `cp -Rn`, rather than relying on tree order in a shared `rcrc`. `install/config/seed-config.sh` still deliberately breaks any symlink under `~/.config` pointing into a checkout — `cp` follows a symlink and writes *through* it, which would silently overwrite the source repository instead of seeding the machine — and that guard matters just as much now that two independent trees seed the same directory.

**The tree lives under `@home`**, which [0001](0001-system-upgrade-snapshots-and-rollback.md) excludes from both backup and restore — so booting a pre-upgrade snapshot reverts the packages but not handaan. `handaan-update` records the pre-update commit to `~/.local/state/handaan/last-update-commit` so the matching state is one `git reset --hard` away. Moving to `/usr/share/handaan` would close the gap properly, at the cost of a package build in the authoring loop.
