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
  uninstall.sh    # optional: sourced when the app is uninstalled, before its config/ and packages
                  #   go -- undoes what install.sh did: systemctl disable, gpasswd -d, a cloned plugin
  config/         # optional: mirrors $HOME, no-clobber copied wholesale when the app is selected --
                  #   e.g. config/.local/share/applications/foo.desktop, config/.config/foo/settings
```

handaan discovers apps and offers each individually:

- `$HOME/.config/handaan/apps/` — supplied by a separate dotfile repository the user owns and maintains, the same private-companion-repo relationship `docs/standards/privacy-policy.md` already describes for `~/.config` overrides. A user who wants an app writes one there; they never fork or patch this repository to get it.

`meta`'s tag reuses the existing `# handaan:summary=` self-declaration convention `bin/handaan-*` scripts already use, rather than inventing a second metadata format.

**Whether an app is installed is handaan's own record, not an inference about it.** `handaan-apps-install` writes a marker to `$HANDAAN_STATE/apps/<app-name>` when it installs one, and an app counts as installed when that marker is present *and* every package it still declares is. Inferring it from the package list alone is wrong in both directions: an app that installs from inside its own `install.sh` declares no packages, so it can never report installed; and an app whose payload is a `config/` tree reports installed the moment anything else pulls in the one package it happens to name, so it is never offered, never selected, and its files are never copied. Keeping the package check on top of the marker is what lets removing a package by hand put the app back in the pending list. `handaan-apps-mark` records an app that was installed before the marker existed, without reinstalling it.

**Installing an app installs that app and touches nothing else.** `handaan-apps-install` runs `yay -S --needed` against the package database as it stands, the way `pacman -S` would. It does not upgrade the system first, and it does not refresh the database with `-Sy`, which without `-u` is the partial upgrade Arch warns against. Upgrading belongs to `handaan update`, which snapshots before it ([0001](0001-system-upgrade-snapshots-and-rollback.md)). `--upgrade` puts the old behaviour back for one run. Until this change, every install ran a full `yay -Syu` first, so adding one small app could become a full system upgrade and a Timeshift snapshot.

**An app can be uninstalled, and the uninstall reads the same files the install does.** `handaan-apps-uninstall <app>...` reverses an install in the opposite order. It does not use a record of what the install did, because the install never kept one, and the app directory already says what the app is:

| step | what happens |
|---|---|
| marker | `$HANDAAN_STATE/apps/<app-name>` is removed first, so a run that dies part-way leaves the app pending rather than claiming an install it has half taken apart. |
| `uninstall.sh` | Sourced in a subshell while the packages are still present, so it can stop and disable what they ship. Without one, nothing `install.sh` did is undone. |
| `config/` | Each file the app ships is compared with the same path under `$HOME`. If it is identical (same bytes, or the same link target for a link the app ships), it is deleted. If it differs, it is moved to `$HANDAAN_STATE/retired-config/apps/<app-name>/`, because the edits were the user's. If the path or any directory above it is a symlink, it is left alone, because another tree deployed it. Directories the removal leaves empty are removed, deepest first. |
| `packages` | The declared list, minus names declared by any other installed app, minus names in `install/*.packages`, minus names no installed package carries. That leaves virtual names (an app declaring `sh`), which have no package of their own to remove. What remains is marked `--asdeps`, and the orphan sweep (`yay -Yc`) removes whatever nothing else requires. |

A package that two apps declare stays as long as either is installed, and one that handaan's core declares always stays. A package something else depends on is not removed but demoted to a dependency, and goes when its last dependent does. `pacman -Rns` would either refuse or take that dependent with it.

**An app is installed or it is not; there is no third state for "removed on purpose".** The app directory stays behind after an uninstall, since it belongs to the dotfile repository and handaan never writes to it, so an uninstalled app reads exactly like one never installed: pending in `handaan pending`, and included in Install all. Removing an app for good is two steps, uninstalling it and then deleting its directory, and the uninstall ends by naming that directory, and what it links to, so the second step is not left to be noticed. A record of removals was tried and dropped: it kept such an app out of the pending count, but it was a second piece of per-machine state to explain, for a case the user resolves by deleting one directory.

Which commands present that offer, and where the picker lives, is [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md); this record is about what an app *is*, when one counts as installed, and what removing one takes back.

## Consequences

Selection becomes flat and per-app, one entry per discovered `apps/<app-name>/` directory, rather than the pre-bundled groups an app menu would otherwise tempt handaan into curating.

`install.sh`, `update.sh` and `uninstall.sh` are arbitrary shell running with the same privileges as the installer, including `sudo`. That is an accepted trust boundary for a single-user system pointing at a repository it owns, not something this record adds a sandbox for.

The marker is per-machine state, so it needs a migration to reach machines that installed apps before it existed; without one, every app they already have reports pending at once. The backfill reproduces the old packages-only answer rather than a better one, so nothing that was ticked before the change comes back unticked — which also means an app that only ever *looked* installed is recorded as installed, since nothing can tell the two apart after the fact.

`handaan-update` sources every discovered app's `update.sh` unconditionally on every run, in addition to the migrations and tool updates it already runs — a second per-app hook alongside migrations, distinguished by scope: a migration repairs one thing once for machines that predate a fix; an app's `update.sh` is ongoing maintenance for as long as that app stays selected.

An install against a stale database can fail: the database names package versions the mirrors have since dropped, and the download 404s. That risk is accepted in exchange for installs that are fast and scoped to what they name. The install recognises the 404, stops, and tells the user to run `handaan update`; it does not upgrade on their behalf. The partial-upgrade risk itself stays: a new package built against libraries newer than the installed ones can install and then fail to start. The same remedy, `handaan update`, applies.

Uninstalling needs no migration and no backfill. It reads the app directory as it is now rather than a record from install time, so every app installed before uninstall existed can be removed the same way. The price of not keeping a record is two known gaps, both accepted for a single-user machine whose apps are how its software arrives:

- A package the user installed by hand *before* an app declared it looks the same as one the app brought, so it is demoted to a dependency and may be swept. `yay -S` brings it back.
- A file the app ships that was already in `$HOME`, byte-identical, before the app was installed is deleted. Nothing is lost by that, since the app directory still holds the same bytes.

Neither the app's `update.sh` nor its `theme/` changes after an uninstall. Both act on every app directory present, installed or not, and `update.sh` was already required to return early when its app is absent.

There is no `all` for uninstall. Removal is named one app at a time, by the person who means it — on the command line, or in the installer on a key of its own that asks twice; see [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md).
