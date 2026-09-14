# 0007. Theme is derived from the selected wallpaper 

Status: accepted

## Context

The wallpapers themselves are partly handaan's, a curated set shipped in the tree, and partly the owner's, which belong in their own dotfiles repository like every other preference.

The wallpaper is picked, and the desktop should look like it belongs to that wallpaper automatically. 

The desktop's colours were Catppuccin Mocha, copied by hand or by a generator into every place that drew one. `bin/handaan-theme-generate` wrote `default/themed/mocha.json` into a Lua table for Hyprland and a QML singleton for the shell, both committed to the tree, so changing a colour meant editing handaan and committing. The wallpaper was a separate thing: `handaan-wallpaper-set` chose a random image (or this month's calendar at login) and, if `wal` happened to be installed, ran it. It never was.


## Decision

**The wallpaper is the only input. The palette follows from it.**

| piece | what it is |
|---|---|
| `bin/handaan-wallpaper-manifest` | The wallpapers on offer, as JSON: every image under `~/.config/handaan/wallpapers` (yours) and `$HANDAAN_PATH/default/wallpapers` (handaan's), yours first, each with the credit from its `.credit` sidecar. |
| `default/wallpapers/README.md` | The credit format, and which licences an image handaan ships may carry. |
| `test/wallpaper-credits.sh` | Fails on an image in `default/wallpapers` without a credit under one of those licences. |
| `bin/handaan-wallpaper-set` | Sets an image (or `--random`, or `--restore` at login) on every monitor, records it in `~/.wallpaper`, derives the palette, and tells Hyprland. |
| `bin/handaan-wallpaper` | Toggles the picker. `Super+Shift+W` calls it. |
| `default/quickshell/Commons/Wallpapers.qml` | Singleton: the list, the current wallpaper, the open state, the `wallpapers` IPC target. |
| `default/quickshell/Ui/WallpaperPicker.qml` | The picker: a grid of thumbnails with Random first. See [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md). |
| `$HANDAAN_STATE/theme/colors.json` | The derived palette. Per-machine state, in neither tree. |
| `default/theme/fallback.json` | Mocha under the same names, for any colour the derived file lacks. |
| `default/hypr/theme.lua` | Reads both files and sets Hyprland's border colours. |
| `default/quickshell/Commons/Colors.qml` | Reads both files, watching the derived one. `Theme.qml` maps it to roles as before. |
| `default/theme/palette.jq` | Maps matugen's scheme onto those names, and keeps the status colours honest. |
| `matugen` | Derives a Material You scheme from the image. In `install/desktop.packages`. |

**handaan ships only wallpapers it may redistribute, and credits each one.** The tree is public, so an image in it is handed to everyone who clones it, and MIT covers handaan's code, not someone else's picture. Every image in `default/wallpapers` has a sidecar, `<image>.credit`, naming its artist, source and licence, and that licence must be CC0, public domain, CC BY or CC BY-SA. `test/wallpaper-credits.sh` enforces it. The picker shows the credit for the wallpaper under the cursor, from either folder; a credit in your own folder is optional. None of the images handaan carried before this could meet that bar -- Smashing Magazine's calendar designs, fan art, and wallpaper-site re-uploads, none with a licence to redistribute -- so all of them moved to the owner's dotfiles, and handaan's set is empty until an openly licensed image is added. Omarchy was not a model here: its theme backgrounds carry no credits at all.

**The palette is state, not a default and not a seed.** It changes at runtime and differs per machine, so a `git pull` must not replace it and a one-time copy could never update it. It lives beside `~/.wallpaper`, which was already the record of what is on screen.

**Both files are flat `{"name": "rrggbb"}` objects under names that describe a place in the scheme** -- `background`, `surface`, `border`, `text`, `textMuted`, `accent`, `accentAlt`, `good`, `warning`, `critical` -- because a wallpaper has no "mauve". The terminal's colours, `ansiBlack` to `ansiBrightWhite`, are the exception, since a terminal names its colours by hue; see [0009](0009-terminal-apps-take-the-desktop-colours.md). Flat because Hyprland's Lua has no JSON library and reads them with a pattern.

**Recolouring a running session needs no reload and no restart.** The palette is renamed into place. Quickshell's `FileView` watches it and every `Theme` binding follows. Hyprland is told with `hyprctl eval 'require("hypr.theme").apply()'`, which runs in the config's own Lua state, so only the border colours change and the rest of the config is not re-run.

**The status colours are blended, never moved out of their hue.** `good`, `warning` and `critical` are given to matugen as custom colours blended toward the wallpaper, so they sit in its palette rather than on top of it. Each is kept only while its hue stays inside a window -- green, orange, red -- and otherwise falls back to the fixed colour, because a status colour's hue is what it means. The accent then gives way to them: on a warm wallpaper matugen's accent is the same peach as `warning`, so the scheme's key colour standing furthest from the status colours becomes the accent instead. Every accent is still one of the wallpaper's own colours. The rules are `default/theme/palette.jq`.

**The scheme is always dark.** Every surface in the shell was designed on a dark ground, and the bar's translucency and the lock screen's scrim both assume one.

**A wallpaper you chose survives a login.** `--restore` puts back what `~/.wallpaper` names and picks at random only when that image is gone. The old login behaviour, a new random image each session and this month's calendar when there was one, is gone with the monthly rule itself: a picker makes a choice, and discarding it at every login would undo that. The calendars that rule existed for were personal rather than curated, so they left `default/wallpapers` for the owner's own `~/.config/handaan/wallpapers`.

**matugen over the alternatives.** It replaces the static Mocha palette, and the dead `wal` hook in `handaan-wallpaper-set`. It is one binary in `extra`, reads an image and prints JSON, and needs no config file or daemon, which is the [simple, durable, scriptable](../../standards/simple-durable-scriptable-tools.md) shape. pywal is not packaged in the official repositories and writes its own cache and templates. aether is an AUR GUI application that applies themes to a dozen targets itself, which is the integrated shape that standard argues against. The cost is one package, and about half a second per wallpaper change.

## Consequences

Nothing in the tree is generated any more, so the "never hand-edit" rule for palette files is gone with the generator.

A border colour set in your own `conf/` modules is overwritten at the next wallpaper change, because `apply()` runs after them. There is no supported override for the border colours today.

rofi still carries its own colours. It is the next consumer, and would read the same state file. The terminal apps handaan installs follow the palette through colour files of their own, and the palette gained the terminal's sixteen colours for them -- see [0009](0009-terminal-apps-take-the-desktop-colours.md). Notifications follow the palette already, being drawn by the shell -- see [0008](0008-notifications-are-part-of-the-desktop-shell.md).

Existing machines need matugen, so `migrations/1789334342.sh` installs it. Without it the wallpaper still changes and the colours stay put, with a warning. The picker and `Colors`' new shape are QML, so the shell needs a restart to see them. Per [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md) that is not a migration: it happens at the next login, and `handaan-wallpaper` says so plainly until it does.
