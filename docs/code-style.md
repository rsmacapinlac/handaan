# Code style

What code in this repository should look like. Only shape: architecture and traps live elsewhere — decisions in [`decisions/adrs/`](decisions/adrs), widget design in [Quickshell widget design](quickshell-widgets.md), and the rules behind all of it in [Standards](standards/README.md). A rule earns a place here by describing what the code already does, so most of this was measured rather than chosen.

## Match the file you are in

This outranks everything below. There is only the file in front of you and its neighbours. If the file looks wrong, say so rather than quietly reformatting it.

Reformatting is not a free action. A whitespace change buries the real edit in a diff nobody can review.

## Comments record why, not what

The single most valuable convention here, and the one that varies most. Keep it brief, don't explain the code unless asked.

## Shell

**Shebang follows where the script runs.** `boot.sh`, `install.sh` and everything under `install/` use `#!/bin/bash`: they run on a known Arch system where the path is certain. Everything in `bin/` uses `#!/usr/bin/env bash`, since those run from a user's `PATH` on machines where bash may not be `/bin/bash` — the headless LXC target included. `bin/tat` and `bin/handaan-hyprlock-capslock` are `#!/bin/sh` on purpose — keep them POSIX, and do not reach for bash features in them.

**Every script that executes sets strict mode**, on the line after the shebang:

```bash
set -euo pipefail
```

**Sourced libraries are the exception, and must not set it.** `install/lib/handaan-common.sh` is sourced into other scripts, where `set -e` would leak into the caller's shell and change behaviour far from the file that set it. A sourced library instead carries a re-entry guard:

```bash
if [[ ${HANDAAN_COMMON_LOADED:-0} == 1 ]]; then
    return 0
fi
HANDAAN_COMMON_LOADED=1
```

Declare the source for shellcheck at the call site, which the existing scripts already do:

```bash
# shellcheck source=install/lib/handaan-common.sh
source "$SCRIPT_DIR/lib/arch-common.sh"
```

**Say what you are doing through the log helpers**, not bare `echo`. `handaan-common.sh` defines `log_info`, `log_success`, `log_warning` and `log_error`; the installer phases and `handaan-*` commands use them so output is consistent and greppable, and so a long bootstrap explains itself while it runs. Keep the aligned one-line form when adding one:

```bash
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
```

**Prefer `[[ ]]` over `[ ]`** in bash, declare function variables `local`, and quote expansions unless you specifically want splitting.

**Indentation is unresolved.** The tree carries both four-space and two-space shell indentation, inherited from the repository handaan grew out of, and it does not split cleanly by directory. No file uses tabs. Until this is ruled on, match the file you are editing and do not convert one on the way past.

## Lua

**Indentation follows the upstream you are configuring, not a house number.** Hyprland's own shipped example config at `/usr/share/hypr/hyprland.lua` indents four spaces. The Hyprland tree here already matches its upstream, so there is no single number to standardise on — picking one would put this repository at odds with the documentation and examples an agent will read while working. When a new Lua tree appears, take its indent from that project's own config, and record it here.

**`config/hypr/` — Hyprland.** Four-space indent, double quotes (376 against 4), one module per concern under `conf/`, and `local` constants hoisted to the top of the file. `config/hypr/hyprland.lua` is a thin loader that `require`s those modules in dependency order and holds no configuration itself; new configuration goes in a module, not in the loader. Table literals align their `=`, and so do runs of related calls:

```lua
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60.01",
    position = "auto",
    scale    = 1.25,
})
```

Align by eye when it makes a block scannable; do not treat it as mandatory, and do not reflow a neighbouring block to keep a column when adding one key. Each module opens with a title comment and the relevant wiki link.

Neovim's own Lua config no longer lives in this repository — it moved to the private companion tree, along with the rest of the app-preference configs that used to sit under `config/`. See [`docs/standards/privacy-policy.md`](standards/privacy-policy.md).

`$HOME` does not expand anywhere in Lua config. Build paths with `os.getenv("HOME") .. "/..."`.

## QML

Four-space indent, unanimous across all ten files. `id: root` is the first line inside a root element, followed by property declarations, then children.

Imports go `QtQuick` first, then the repository's own modules:

```qml
import QtQuick
import qs.Commons
```

Widgets carry a file-header comment stating the question the widget answers before any code — see the top of `modules/Battery.qml`, which names its two questions and explains what was deliberately left out. That header is the widget's design record, and [Quickshell widget design](quickshell-widgets.md) governs what belongs in it.

## hyprlang

`hyprlock`, `hypridle` and `hyprpaper` stay in hyprlang while Hyprland itself is Lua. Two-space indent inside blocks, `#` comments, uppercase section headers, and `$variables` defined near the top after any `source =` line.

## Generated files

Three files are generated from `default/themed/mocha.json` by `bin/handaan-theme-generate` and must never be hand-edited:

- `default/hypr/colors.conf`
- `default/hypr/colors.lua`
- `default/quickshell/Commons/Colors.qml`

Edit the source and regenerate. An edit made directly to one of these survives until the next regenerate and then vanishes, which is a confusing way to lose an afternoon.
