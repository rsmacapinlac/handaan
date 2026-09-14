# ADR Changelog

## 2026-09-13 (notifications in the shell)

- **0008** written. The Quickshell shell is the notification daemon: popups top right of the focused monitor, a session-only history, and do-not-disturb, in `Commons/NotificationCenter.qml` with `Ui/NotificationToasts.qml`, `Ui/NotificationHistory.qml` and the bar's always-present `modules/Bell.qml`, reached by `Super+Shift+N` and `bin/handaan-notifications`. mako stays installed as the fallback but its unit is masked, because its D-Bus activation file would otherwise start it before the shell and keep the shell from ever owning the name; `migrations/1789334343.sh` masks it on installed machines.
- **0007** edited in place. Its note that mako carried its own colours no longer holds.

## 2026-09-13 (colours from the wallpaper)

- **0007** written. The desktop's colours are derived from the wallpaper with matugen, into `$HANDAAN_STATE/theme/colors.json`, and read live by Hyprland (`default/hypr/theme.lua`, applied through `hyprctl eval`) and the shell (`Commons/Colors.qml`, watching the file). There is no theme to choose. `bin/handaan-theme-generate`, `default/themed/mocha.json` and the two palette files it generated are gone; Mocha survives as `default/theme/fallback.json`. The status colours are blended toward the wallpaper but held to their hue, and the accent yields to them when the two would collide (`default/theme/palette.jq`). Wallpapers come from `~/.config/handaan/wallpapers` as well as handaan's own set, the monthly-calendar rule is dropped and its calendars moved out of `default/wallpapers` to the private repository, and login restores the wallpaper you chose rather than picking a new one.
- **0007** also covers wallpaper credits. Every image in `default/wallpapers` needs a `.credit` sidecar with an artist, source and a redistributable licence, checked by `test/wallpaper-credits.sh` and shown in the picker. No image handaan carried qualified, so all 39 moved to the private repository.
- **0006** edited in place. The wallpaper picker, `Commons/Wallpapers.qml` and `Ui/WallpaperPicker.qml` summoned by `bin/handaan-wallpaper` on `Super+Shift+W`, is the third dialog built this way.

## 2026-09-13 (lock screen in the shell)

- **0006** edited in place. The power menu's Lock no longer runs `loginctl lock-session`; it asks the shell's lock screen directly.

## 2026-09-13 (power menu in the shell)

- **0006** edited in place. The rofi power menu, `config/waybar/scripts/powermenu.sh`, moved into the shell as `Commons/SessionControl.qml` and `Ui/PowerMenu.qml`, summoned by `bin/handaan-session`. It had written a temp theme into the user's `~/.config/rofi` on every run and hardcoded a Mocha a regenerate could not reach; it named a font no package installs; its lock bypassed hypridle's single-instance guard; and restart and shut down ran on one keypress. It is a filterable single row of actions, and log out, restart and shut down now confirm. That was the last thing only Waybar offered, so Waybar went with it: the package, its `config/waybar/` seed, and the fallback-bar wording in `AGENTS.md` and `docs/hyprland-startup.md`. `migrations/1789324024.sh` uninstalls it from installed machines and leaves `~/.config/waybar` to its owner.

## 2026-09-12 (installer in the shell)

- **0006** written. handaan's own dialogs are part of the desktop rather than separate applications: the app picker moved into the Quickshell process as `Commons/AppCatalog.qml` and `Ui/Installer.qml`, so it binds to `Theme` instead of carrying a hand-copied palette a regenerate could not reach. The inversion also deleted the handshake that existed only because a script was driving a GUI -- the env-var app list, the selection temp file, the stdout redirect, the self re-exec into a terminal -- and split `handaan-apps` into single-purpose helpers the shell calls. The dialog is a launcher rather than a checkbox form: type to narrow, `Enter` installs the row under the cursor, and `Install all pending` is a row in the same list that confirms before it runs.
- **0005** edited in place. It named `handaan-apps` as the thing that discovers apps, offers them and writes the install marker; that command now only summons the dialog. The record points at the commands that replaced it and defers the question of *how* apps are presented to 0006, keeping itself to what an app is and when one counts as installed.


## 2026-09-09 (monitors)

- **0003** edited in place. Its two-tree table asks which tree a file belongs in and assumed one answer per file. 

## 2026-09-06 (app install state)

- **0005** edited in place. It described how an app is *defined* but never how handaan decides one is *installed*, and the implementation inferred it from the package list alone. That was wrong in both directions -- apps installing from inside `install.sh` declared no packages and could never report installed, while an app whose payload was a `config/` tree reported installed as soon as anything else pulled in the one package it named, so it was never selected and its files were never copied. The record now names the marker under `$HANDAAN_STATE/apps/` as the answer, with the package check kept on top of it.


## 2026-09-06 (seeding)

- **0003** edited in place. It endorsed `seed-config.sh` breaking every symlink under `~/.config` that pointed into a checkout, calling the guard one that "matters just as much now that two independent trees seed the same directory". It mattered in the opposite direction: the sweep deleted the live deployment of any dotfile repository that still uses symlinks, three levels deep, on every installer run. The write-through hazard it was guarding against is real and is now closed by seeding file-by-file and skipping paths another tree owns, rather than by deleting anything.


## 2026-09-06 (login shell)

- **0003** edited in place. Its env-bootstrap consumer list named `~/.zshenv` as one of the entry points handaan wires; handaan no longer writes that file. The list now names only the three handaan owns, and says that a non-login interactive shell — which none of them reach — has to source env-bootstrap from the user's own rc. The VM-rehearsal paragraph reads in the past tense about `chsh`.


## 2026-09-06 (apps)

- **0005** written. Optional applications are a per-app directory convention (`apps/<app-name>/`: `meta`, `packages`, `install.sh`, `update.sh`, `config/`), discovered from a user-owned dotfile repository at `~/.config/handaan/apps/` rather than curated inside this repository -- so adding an application never means forking handaan.

## 2026-09-06

- **0004** edited in place. Its Consequences section stated "the installer handles the fresh case and a migration handles the installed one" as an aside; that rule is now written up as its own standard, [Fresh installs carry every fix](../../standards/fresh-installs-carry-every-fix.md), and 0004 links to it rather than restating it.

- **0003** edited in place. The private companion repository's override mechanism, previously described as unbuilt, has been rebuilt on the copy model — and most of what it was meant to override no longer needs overriding at all: most app-preference configs (tmux, nvim, kitty, and others) moved out of handaan's `config/` entirely, leaving Hyprland/hyprlock/hypridle/hyprpaper, rofi, waybar and mako there. `docs/standards/privacy-policy.md` (then named `privacy.md`) and `AGENTS.md` updated to match.

## 2026-09-05 (handaan)

- **0003** and **0004** written together as part of the move from the `dots` dotfile repository to handaan. They are separable decisions — a tree that owns itself does not require migrations, and migrations would work under `rcm` — but each is half the answer to the same question: what is allowed to change on an installed machine, and by what mechanism.
- **0002** edited in place. The bootstrap now clones the tree to `$HANDAAN_PATH` and runs the installer out of it, rather than downloading two scripts to a temp directory. The `curl | bash` delivery and both guards it forced are unchanged.


## 2026-09-05

- **Records are now edited in place** rather than superseded, and this file was added. Supersession assumed a record described a moment; in practice each describes a standing question, and it is the answer that moves.
- **0002** written. The `curl | bash` delivery and the single dispatcher script are one decision, not two — `run_with_terminal` and the empty-file guard in `download` exist only because of the pipe.

## 2026-09-04

- **0001** written. GRUB, btrfs and Timeshift are one record rather than three: the requirement to boot a pre-upgrade snapshot forces all three, and separately each would read as an arbitrary preference.
