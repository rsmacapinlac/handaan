# 0005. Accept optional applications from a user-owned repository

Status: accepted

## Context

handaan's installer stops at a minimal, working desktop (see `docs/standards/core-stays-minimal.md`). handaan does not ship, and does not maintain an opinion about, the applications someone runs on top of that desktop — development tools, browsers beyond the one core installs, media apps, whatever a given person actually uses.

A user adopting handaan needs an actual way to add their own applications without forking this repository to do it. Forking to carry a package list, or asking the maintainer to add an app on their behalf, is not integration — it makes a person's own applications someone else's file to edit. Whatever that way is, it also has to work one application at a time: a person should be able to add exactly the one thing they want, not accept it bundled with others they don't.

## Decision

An **app** is a self-contained directory in a person's dotfile repository, not a case in a script:

```
apps/<app-name>/
  meta            # handaan:summary=One line, shown in the selection menu
  packages        # optional: package list, comments/blanks stripped -- same shape as install/*.packages
  install.sh      # optional: sourced once, when the app is (re)selected -- modprobe, systemctl enable,
                  #   usermod, multilib, or whatever one-time setup the app needs
  update.sh       # optional: sourced unconditionally on every `handaan update`, for anything
                  #   package-manager upgrade of the app doesn't catch
  config/         # optional: mirrors $HOME, no-clobber copied wholesale when the app is selected --
                  #   e.g. config/.local/share/applications/foo.desktop, config/.config/foo/settings
```

`handaan-apps` discovers apps and offers each individually:

- `$HOME/.config/handaan/apps/` — supplied by a separate dotfile repository the user owns and maintains, the same private-companion-repo relationship `docs/standards/privacy-policy.md` already describes for `~/.config` overrides. A user who wants an app writes one there; they never fork or patch this repository to get it.

`meta`'s tag reuses the existing `# handaan:summary=` self-declaration convention `bin/handaan-*` scripts already use, rather than inventing a second metadata format.

**Whether an app is installed is handaan's own record, not an inference about it.** `handaan-apps` writes a marker to `$HANDAAN_STATE/apps/<app-name>` when it installs one, and an app counts as installed when that marker is present *and* every package it still declares is. Inferring it from the package list alone is wrong in both directions: an app that installs from inside its own `install.sh` declares no packages, so it can never report installed; and an app whose payload is a `config/` tree reports installed the moment anything else pulls in the one package it happens to name, so it is never offered, never selected, and its files are never copied. Keeping the package check on top of the marker is what lets removing a package by hand put the app back in the pending list. `handaan-apps --mark` records an app that was installed before the marker existed, without reinstalling it.

## Consequences

Selection becomes flat and per-app, one entry per discovered `apps/<app-name>/` directory, rather than the pre-bundled groups an app menu would otherwise tempt handaan into curating.

`install.sh` and `update.sh` are arbitrary shell running with the same privileges as the installer, including `sudo`. That is an accepted trust boundary for a single-user system pointing at a repository it owns, not something this record adds a sandbox for.

The marker is per-machine state, so it needs a migration to reach machines that installed apps before it existed; without one, every app they already have reports pending at once. The backfill reproduces the old packages-only answer rather than a better one, so nothing that was ticked before the change comes back unticked — which also means an app that only ever *looked* installed is recorded as installed, since nothing can tell the two apart after the fact.

`handaan-update` now sources every discovered app's `update.sh` unconditionally on every run, in addition to the migrations and tool updates it already runs — a second per-app hook alongside migrations, distinguished by scope: a migration repairs one thing once for machines that predate a fix; an app's `update.sh` is ongoing maintenance for as long as that app stays selected.
