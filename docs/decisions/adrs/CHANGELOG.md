# ADR Changelog


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
