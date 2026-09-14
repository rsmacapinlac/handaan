# 0009. Terminal apps take the desktop's colours

Status: accepted

## Context

[0007](0007-take-the-desktop-colours-from-the-wallpaper.md) derives the desktop's colours from the wallpaper, and Hyprland and the shell read them live. The terminal apps did not. kitty, Neovim, btop and lazygit carried Catppuccin Mocha, or their own defaults, set in configs that live in the owner's dotfiles, and nmtui -- opened from the bar's network widget -- drew newt's blue and red. So a wallpaper change recoloured the frame around a terminal and nothing inside it.

A terminal app cannot read the palette the way Hyprland and the shell do. Each wants colours in a format of its own, most read them only at start, and none of them knows where handaan keeps anything. The palette also lacked what a terminal needs most: its sixteen ANSI colours, which fzf, htop, ranger, git and every shell prompt draw with.

The configs for these apps are the owner's, not handaan's, so handaan cannot simply write colours into them. And the same problem will come up for apps handaan does not install -- tmux, a mail client, a music player -- which live in the owner's `~/.config/handaan/apps`.

## Decision

**The palette gains the terminal's colours, and each terminal app gets a colour file written from a template on every wallpaper change.** Templates are an extension point: handaan ships them for the apps it installs, and an app in `~/.config/handaan/apps` can bring its own.

| piece | what it is |
|---|---|
| `ansiBlack` … `ansiBrightWhite` | Ten new palette names, in `default/theme/fallback.json` (Mocha) and derived by `default/theme/palette.jq`. |
| `bin/handaan-theme-render` | Writes every template into `$HANDAAN_STATE/theme/`, then runs its reload hook. Called by `handaan-wallpaper-set`. |
| `default/theme/templates/<file>` | handaan's templates: `kitty.conf`, `btop.theme`, `lazygit.yml`, `newt-colors`. |
| `default/theme/templates/<file>.reload` | Optional, run after its file is written. `kitty.conf.reload` sends kitty `SIGUSR1`. |
| `~/.config/handaan/apps/<app>/theme/<file>` | An app's own template, with an optional `.reload` the same way. Replaces handaan's if it has the same file name. |
| `default/nvim/colors/handaan.lua` | Neovim's colorscheme. Reads the palette itself and watches it, so it has no template. |
| `default/shell/env-bootstrap` | Sets `NEWT_COLORS_FILE`, and `LG_CONFIG_FILE` with your own lazygit config after the colours. |
| `config/btop/btop.conf` | Seed choosing `color_theme = "handaan"`. |
| `install/config/terminal-colours.sh` | Writes the first set of files and links `~/.config/btop/themes/handaan.theme` to the rendered theme. |
| `migrations/1789358448.sh` | The same on an installed machine, plus the btop seed where there is no `btop.conf` yet. |

**A template is the app's own format with `{{name}}` wherever a palette colour goes**, replaced by bare `rrggbb`, so a template writes `#{{accent}}` where the app wants a hash. The names are the palette's, from `fallback.json`. A template naming a colour the palette does not have is not written, and the last good file stays, because most apps reject a whole file for one bad line. A file is renamed into place, so an app starting mid-write never reads half of one.

**How each app reaches its file:**

| app | how | recolours a running copy |
|---|---|---|
| kitty | `include ~/.local/state/handaan/theme/kitty.conf` in your `kitty.conf` | yes, on `SIGUSR1` |
| Neovim | `default/nvim` on the runtimepath, then `colorscheme handaan` | yes, it watches `colors.json` |
| btop | theme `handaan`, found through the link in `~/.config/btop/themes` | no, at next start |
| lazygit | `LG_CONFIG_FILE`, from the session environment | no, at next start |
| nmtui | `NEWT_COLORS_FILE`, from the session environment | no, at next start |

kitty and Neovim need a line in your own config, because they offer no other way in. btop needs its seed, or `color_theme = "handaan"` in a `btop.conf` you already had. lazygit and nmtui need nothing.

**The terminal's hues follow the status colours' rule.** Yellow, blue, magenta and cyan are blended toward the wallpaper by matugen and held to a window of hue, falling back to Mocha's when a blend carries them out of it, because a red in a diff has to read as red. Red and green are `critical` and `good` themselves, so a failing test and a critical notification are one colour. Bright hues are the normal ones, as Catppuccin's are; black and white each get a brighter step from the scheme's own greys.

**Neovim colours syntax from the terminal's hues, not the accents**, so code looks alike in Neovim and in anything else printing to the terminal, and the accent stays reserved for what is selected or current.

**btop is linked, not pointed at a path.** btop finds a theme only by name in its themes directory; an absolute path in `color_theme` silently falls back to the default theme. The link points at the rendered file, so it never needs updating. Nothing is linked through a `~/.config/btop` that is itself a symlink into another tree -- the rule `seed-config.sh` follows.

**lazygit's list is built only from files that exist.** lazygit refuses to start if any file named in `LG_CONFIG_FILE` is missing, and it creates none of them. So `env-bootstrap` lists the colours only once they have been written, and your `config.yml` only if you have one, and a list you set yourself is left alone.

matugen already derives the palette, so this adds no dependency. matugen's own template engine was not used: templates are filled from the finished palette, after `palette.jq` has held the hues and moved the accent, which matugen's templates run before.

## Consequences

A wallpaper change now also writes four files and signals kitty. btop, lazygit and nmtui show the new colours the next time they start.

Changing `kitty.conf` or your Neovim config is yours to do: handaan does not touch either, and the migration prints the lines. A colour you set after the `include` in `kitty.conf` still wins, and so does anything in your lazygit `config.yml`.

`LG_CONFIG_FILE` and `NEWT_COLORS_FILE` reach the session at the next login, since uwsm reads `env-bootstrap` only then. A shell sources it every time it starts, so a lazygit `config.yml` created later is picked up by the next shell.

A new template from a `git pull` is written at the next wallpaper change or login, not at the pull.
