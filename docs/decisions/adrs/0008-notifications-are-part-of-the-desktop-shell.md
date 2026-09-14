# 0008. Notifications are part of the desktop shell

Status: accepted

## Context

mako drew the desktop's notifications. It did the one job and nothing more: a popup that timed out, configured in `~/.config/mako/config`, which on this machine was mako's own defaults -- a 45-second timeout and a blue that belonged to no palette. There was no history, so a notification that timed out while you were away was gone, and no do-not-disturb.

Everything else handaan draws already lives in one Quickshell process and follows the wallpaper's palette ([0007](0007-take-the-desktop-colours-from-the-wallpaper.md)). A notification was the one surface on the desktop that did not, and could not without a second copy of the palette in mako's syntax.

## Decision

**The Quickshell shell is the session's notification daemon.** It draws popups, keeps a history, and has a do-not-disturb switch.

| piece | what it is |
|---|---|
| `default/quickshell/Commons/NotificationCenter.qml` | Singleton. Owns `org.freedesktop.Notifications` through Quickshell's `NotificationServer`, the history, the popups on screen, do-not-disturb, and the `notificationCenter` IPC target. |
| `default/quickshell/Ui/NotificationCard.qml` | One notification: app, age, summary, body, action buttons. The same card as a popup and in the history. |
| `default/quickshell/Ui/NotificationToasts.qml` | Popups, top right of the focused monitor, at most four. |
| `default/quickshell/Ui/NotificationHistory.qml` | The history panel, with the do-not-disturb switch and Clear all. |
| `default/quickshell/modules/Bell.qml` | The bar indicator, always present: grey when nothing is unseen, the accent when something is, a slashed bell while do-not-disturb is on. |
| `bin/handaan-notifications` | Toggles the panel; `dnd on\|off\|toggle`, `clear`, `status`. `Super+Shift+N` calls it. |
| `$HANDAAN_STATE/notifications/do-not-disturb` | Whether do-not-disturb is on. The only notification state written to disk. |

**How long a popup stays is the sender's to say.** The protocol's `expire_timeout` is honoured, in milliseconds; a sender that leaves it to the server gets 8 seconds, and one that asks for 0 stays. Critical stays until dismissed whatever the sender says.

**A timed-out popup leaves the screen, not the history.** The notification stays tracked until you dismiss it there or clear the history, which is what lets its action buttons still work from the panel, and why the server declares persistence. A notification its own app closes -- a message read on another device -- is removed from both. A transient notification is never kept. History is capped at 100, and the oldest past that are expired so their senders are told.

**History lives in memory.** Notifications carry message previews and senders, so none of that is written to disk; a shell restart or a logout starts the history empty. Do-not-disturb is remembered, since forgetting it at login would undo it.

**Do-not-disturb holds popups, not notifications.** They still arrive in the history, unseen, and the bell says so. Critical still pops up.

**Nothing pops up over the lock screen.** A notification arriving while locked goes to the history unseen, and nothing replays as a popup on unlock.

**Opening the history is reading it.** Every notification is marked seen the moment the panel opens, which is what quiets the bell; there is no per-card read state.

**mako is masked, not removed.** Only one program can own `org.freedesktop.Notifications`. Disabling `mako.service` is not enough: mako's package ships a D-Bus activation file naming that service, so the first notification sent before the shell is up would start mako, mako would take the name, and the shell's server would silently fail to register. Masking the unit makes that activation fail. The package stays installed as the fallback until the shell's notifications have proven themselves, the way waybar stayed beside the Quickshell bar; `~/.config/mako` is the user's and is left alone.

This replaces mako with nothing new to install -- `Quickshell.Services.Notifications` ships with the `quickshell` package already in core. What it serves better is [configuration is modular](../standards/configuration-is-modular.md) and the palette: notification appearance is QML in `default/`, updated by a `git pull` and coloured by `Theme`, rather than a seeded file that no update reaches.

## Consequences

Notifications now share the shell's process. If Quickshell is down, nothing receives notifications -- mako is masked, so it does not step in -- and `notify-send` fails rather than falling back. That is the same trade [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md) made for dialogs, with `Restart=on-failure` on the unit the same mitigation. `handaan-notifications` says plainly when the shell is not running.

`install/post-install/services.sh` disables and masks `mako.service` on a fresh install. `migrations/1789334343.sh` does the same on an installed machine, and deliberately does not stop the running mako: it keeps notifications working until the next login, when the shell claims the name. To switch at once, stop mako before restarting the shell -- a shell restarted while mako holds the name cannot take it.

Removing mako entirely -- the package and its `config/mako` seed -- is a later change, once the shell has carried notifications for a while.
