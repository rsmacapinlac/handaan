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

**A single configuration file can belong in both trees, and is then split rather than placed.** The table above asks which tree a file belongs in and assumes one answer per file. Monitor configuration showed that is not always true — `hypr/conf/monitors.lua` held a *description* of one machine's screens, which handaan cannot ship without pinning every machine to somebody else's panel, alongside the *mechanism* that runs when screens change, which handaan cannot leave unfixable on a machine already running. Where the two are mixed, split by that distinction rather than by application: description stays a `config/` seed, mechanism moves to `default/`. `default/hypr/monitors.lua` carries only `hl.on` subscriptions and no `hl.monitor` call; the seed carries rules and no subscriptions.

**A new `default/` module is reached by chaining a `require` from a default already in the user's list — never by adding a line to that list.** The list lives in `~/.config/hypr/hyprland.lua`, which is seeded once and may never be written to again, so a default that arrives only when the user edits their own file does not reach an installed machine at all. `default/hypr/monitors.lua` is required from the end of `default/hypr/autostart.lua`, so a `git pull` alone delivers it: no migration, and nothing written under `~/.config`. Chain from the default whose concern is closest — monitor events are session wiring, which is what `autostart.lua` already does. The alternative was a migration editing the user's loader, which is precisely the write this record forbids.

**The seed is `cp -Rn`, not `cp -R`.** Refusing to clobber is what makes a second run safe: a failed bootstrap can be retried without losing edits made between the attempts.

**`$HANDAAN_PATH` is never hardcoded.** `default/shell/env-bootstrap` is the single source of truth, sourced by `/etc/profile.d/handaan.sh` (every login shell), `~/.config/uwsm/env` (the graphical session, which inherits no interactive `PATH`) and `install.sh` — and, from outside this repository, by whatever the user's own shell rc does for a non-login interactive shell, which none of those three reach — handaan seeds no shell rc file of its own. It reads `/etc/handaan.conf` first if that file exists. Nothing writes that file today; it is the seam that makes relocating the tree — to `/usr/share/handaan` as a pacman package, say — a change to one file rather than a grep across the repository.

Wiring **only** `~/.zshenv` is not enough, and the first VM rehearsal proved it: zsh was the login shell handaan set at the time, so everything looked correct, while a bash login, an ssh command and a TTY opened before `chsh` took effect all came up with `handaan-*` simply "command not found". The failure is silent because `~/.zshenv` is what sets `$HANDAAN_PATH` in the case anyone checks by hand. handaan no longer sets a login shell at all, which makes this rehearsal *more* relevant rather than less: the account's shell is now whatever the user chose, and `/etc/profile.d/handaan.sh` is what has to hold for all of them.

## Consequences

**The cost is that an edit to `~/.config` no longer lands in git.** That is the deliberate trade, and it needs tooling rather than discipline, so three commands exist: `handaan-diff-config` lists what has drifted, `handaan-refresh-config` takes a newer default (with a timestamped backup and a diff), and `handaan-promote-config` sends a good local edit back into the tree. `handaan-update` reports the drift count at the end of every run, because drift that nobody is told about is drift that gets discovered during a rebuild, when it is already gone.

**`rcm` is no longer used.** The private companion repository's override mechanism, which depended entirely on `rcm` tree ordering, has since been rebuilt on the same copy model: it now seeds `~/.config` itself with the same no-clobber `cp -Rn`, rather than relying on tree order in a shared `rcrc`. `install/config/seed-config.sh` used to break any symlink under `~/.config` pointing into a checkout, on the reasoning that `cp` follows a symlink and writes *through* it. The hazard is real but the guard was far wider than it: it deleted every such link three levels deep, on every installer run, including the live deployment of a dotfile repository that had not migrated off symlinks at all. The seed now copies one file at a time, never deletes, and skips any path whose parent is a symlink out of the tree — which closes the write-through hole without touching anything handaan does not seed.

**Chaining has a cost that grows.** Each new `default/hypr/` module means choosing a parent to chain from, or accepting that it reaches fresh installs only — worse than a flat list, and the price of the list living in a file handaan may not edit. Past two or three, the answer is a single `default/hypr/handaan.lua` requiring the rest, not a line in the user's config. And whether a split needs a migration has to be *checked*, not assumed: the monitors split needed none only because a machine predating it keeps its old subscriptions while the new default registers them again, and `handaan-lid-switch sync` takes a non-blocking `flock` so the duplicate is a no-op rather than a double reconcile.

**The tree lives under `@home`**, which [0001](0001-system-upgrade-snapshots-and-rollback.md) excludes from both backup and restore — so booting a pre-upgrade snapshot reverts the packages but not handaan. `handaan-update` records the pre-update commit to `~/.local/state/handaan/last-update-commit` so the matching state is one `git reset --hard` away. Moving to `/usr/share/handaan` would close the gap properly, at the cost of a package build in the authoring loop.
