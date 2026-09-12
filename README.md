# handaan

A minimal, recreatable single-user Arch + Hyprland desktop that installs into its own tree and can rebuild a machine in 10–15 minutes.

It is optimized for the hardware I own, and it caters to two use cases: an ordinary desktop (browsing, office tools) and a terminal workspace. It extends with your own tools and apps, which you add from a repository of your own rather than by forking this one — see [Extending handaan with your own applications](docs/extending-with-apps.md).

The terminal workspace means the tooling — Kitty, Neovim, ranger, ripgrep, fzf, lazygit. It does not include a shell or a multiplexer: handaan installs no shell, runs no `chsh`, and does not install tmux, because those come with configuration that is yours rather than handaan's. Both are `handaan apps` away, supplied from your own dotfile repository.

You inherit my hyprland keybindings and quickshell rice (which isn't much now - but this will hopefully improve over time).

handaan is the successor to my `dots` dotfile repository, rebuilt around [Omarchy](https://omarchy.org)'s installation model — a single owned tree, defaults you never edit, and migrations that reach machines that are already installed. Their design is far better thought out than mine; a good deal of this is adapted from it.

You're more than **welcome** to use it. See Contributing.

## The stance on AI

AI is welcome here. The guardrails are written down, and explicit, in [`AGENTS.md`](AGENTS.md). If a guardrail turns out to be wrong, fix the guardrail. Don't work around it and leave the next session to rediscover why.

## Quick setup

### This is Arch BTW

Burn the ISO, boot it, get an internet connection, then run the command below. Read [the archinstall notes](install/archinstall/README.md) before installing onto hardware you care about.

```bash
# on the live ISO
curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash

# reboot into the installed system, log in at the TTY, run the same command
sudo reboot
curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash

# reboot into Hyprland, then pick any of your own optional applications
sudo reboot
handaan apps
```

The second run clones this repository to `~/.local/share/handaan` and installs from there. That checkout *is* handaan on the installed machine — it is not a build artifact, and every path in the running system resolves back into it.

## How it is laid out

| | what it is |
|---|---|
| `default/` | handaan's. Read live from `$HANDAAN_PATH`. **Never edit these on a machine** — an update replaces them. |
| `config/` | Seeds `~/.config` once at install. After that the copy in `~/.config` is yours and no update touches it. |
| `bin/` | The `handaan-*` commands, on `PATH`. Run `handaan` to list them. |
| `install/` | The installer, as small one-concern scripts grouped by phase. |
| `migrations/` | One-shot fixes for machines installed before a change landed. |
| `docs/` | Why things are the way they are. [Standards](docs/standards/README.md) and [decisions](docs/decisions/README.md). |

## Everyday commands

```bash
handaan                      # list every command
handaan update               # packages, migrations, tools -- snapshot first
handaan migrate              # apply pending migrations only
handaan diff-config          # what in ~/.config has drifted from the defaults
handaan refresh-config <p>   # take a newer default (backs up yours first)
handaan promote-config <p>   # send a local edit back into the tree
handaan apps                 # pick your own optional applications
handaan apps-install <name>  # ...or install one without the dialog
```

## Development setup

Development happens directly against the checkout named above — `$HANDAAN_PATH`, `~/.local/share/handaan` by default — since that checkout *is* the running system, not a separate clone you sync in from elsewhere.

To push changes back to GitHub, point `origin` at your fork (or this repo, if you have write access) over SSH, and make sure a key registered with GitHub is unlocked in an agent:

```bash
git remote set-url origin git@github.com:<you>/handaan.git
ssh-add -l   # confirm a key is loaded; ssh-add ~/.ssh/<key> if not
```
## Contributing

I'm not claiming that I know everything. I'm continually learning and adjusting. I am a firm believer that collaboration makes the end result much better.

So that said, I hope you see whats been done and contribute.

You are more than welcome to:
- Fork and adapt for your own use
- Submit issues for bugs or improvements
- Share configuration ideas via discussions

## License

MIT License - Feel free to use and modify as needed.
