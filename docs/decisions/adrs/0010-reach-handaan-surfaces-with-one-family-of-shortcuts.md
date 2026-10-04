# 0010. Reach handaan's surfaces with one family of shortcuts

Status: accepted

## Context

handaan draws several surfaces you summon -- the app installer, the wallpaper picker, the island, the session menu -- and each needs a key. They arrived one at a time, and each record that added one ([0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md), [0007](0007-take-the-desktop-colours-from-the-wallpaper.md), [0008](0008-notifications-are-part-of-the-desktop-shell.md)) said which key called it without saying why that key. The pattern they share was real but written nowhere, so the next surface had nothing to follow: the island's first shortcut was `Super+N`, chosen because it was free, and it sat outside the family it belonged to.

## Decision

**A handaan surface is reached with `Super+Shift+<letter>`, and the key toggles it.**

| key | surface | command |
|---|---|---|
| `Super+Shift+A` | app installer | `bin/handaan-apps` |
| `Super+Shift+W` | wallpaper picker | `bin/handaan-wallpaper` |
| `Super+Shift+N` | the island, on the focused monitor | `bin/handaan-island` |
| `Ctrl+Alt+Delete` | session menu | `bin/handaan-session` |

The binds live in `default/hypr/binds.lua`.

- **The key runs a `bin/handaan-*` command, never the shell's IPC directly.** The command is the same door from a terminal, and it can say plainly when the shell is not running, which a bind cannot.
- **The command toggles.** A second press puts the surface away the way the first brought it up, so the key is the whole of how you use it. `Escape` closes it as well. The installer is out of line here: `handaan-apps` calls `appCatalog open`, so a second `Super+Shift+A` re-reads the catalogue rather than closing it. Recorded rather than reconciled, until someone brings it into line.
- **The letter says what the surface is for.** The island holds notifications, and took `N` from the history panel it replaced as the place they are read.
- **Plain `Super+<key>` is the window manager's** -- workspaces, focus, the terminal, the launcher. Keeping handaan's surfaces behind `Shift` means neither ever has to give way to the other.

**`Ctrl+Alt+Delete` is the one exception.** It already means "the session" everywhere else, and a session menu reached any other way would be the one key here a newcomer could not guess.

A new surface takes the next free `Super+Shift` letter that names it. Choosing anything else means writing down why, here.

## Consequences

The history panel lost its key when the island took `N`, and is reached only through `handaan notifications`. That is deliberate: the island holds the same list, and a second key to a second copy of it would be two places to go for one thing.

The family is a convention, not something the config enforces: nothing stops a bind outside it, and only this record says it is wrong.
