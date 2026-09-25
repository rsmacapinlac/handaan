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
| `default/quickshell/Ui/NotificationPopups.qml` | Popups, top centre of the focused monitor, under the island, at most four. Was `NotificationToasts.qml`. |
| `default/quickshell/Ui/NotificationHistory.qml` | The history panel, with the do-not-disturb switch and Clear all. |
| `default/quickshell/Ui/Island.qml` | The bar indicator, as a badge on the island: present while anything is kept or do-not-disturb is on, coloured by the most urgent notification kept -- critical red, normal the accent, low grey -- and slashed while do-not-disturb is on. Clicking the island's cut-out expands the island's own history and controls; clicking outside collapses it. The separate history dialog remains available by keyboard shortcut or command. This was `modules/Bell.qml`, a card in the widgets section, until the island took notifications; that file is still in the tree but nothing references it. |
| `bin/handaan-notifications` | Toggles the panel; `dnd on\|off\|toggle`, `clear`, `status`. `Super+Shift+N` calls it. |
| `$HANDAAN_STATE/notifications/do-not-disturb` | Whether do-not-disturb is on. The only notification state written to disk. |

**A popup stays two seconds, and the sender does not get a say.** The protocol's `expire_timeout` is ignored -- a sender asking for forty-five seconds, or to stay forever, gets the same two as everything else. Critical is not an exception either. This reverses the original decision, which honoured `expire_timeout` and let critical stay until dismissed, and it is the island that makes the reversal safe: a popup leaving used to mean the notification was reachable only through a panel you had to remember to open, and now it is in the island, visible in the badge and there when you open it. The popup only has to be long enough to notice.

Each popup has its own countdown from its arrival. Another popup arriving or closing does not restart it. Hover holds only that popup; leaving gives it at least 1.5 seconds before it disappears. Replacing a notification starts a fresh countdown for that notification alone.

**A timed-out popup leaves the screen, not the history.** The notification stays tracked until you dismiss it there or clear the history, which is what lets its action buttons still work from the panel, and why the server declares persistence. A notification its own app closes -- a message read on another device -- is removed from both. A transient notification is never kept. History is capped at 100, and the oldest past that are expired so their senders are told.

**History lives in memory.** Notifications carry message previews and senders, so none of that is written to disk; a shell restart or a logout starts the history empty. Do-not-disturb is remembered, since forgetting it at login would undo it.

**Do-not-disturb holds popups, not notifications.** They still arrive in the history, and the bell appears in their colour. Critical still pops up.

**Nothing pops up over the lock screen.** A notification arriving while locked goes to the history unseen, and nothing replays as a popup on unlock.

**Opening the history is reading it.** Every notification is marked seen the moment the panel opens; there is no per-card read state. Seen does not take the bell away -- only dismissing does, because a notification you have read but not dealt with is still waiting.

**No other notification daemon is installed.** Only one program can own `org.freedesktop.Notifications`, and a daemon's package ships a D-Bus activation file, so the first notification sent before the shell is up would start that daemon, it would take the name, and the shell's server would silently fail to register. Disabling its unit does not stop that. mako was first kept installed with its unit masked, as a fallback while the shell's notifications proved themselves, the way waybar stayed beside the Quickshell bar. It has since been removed, along with its `config/mako` seed.

This replaces mako with nothing new to install -- `Quickshell.Services.Notifications` ships with the `quickshell` package already in core. What it serves better is [configuration is modular](../standards/configuration-is-modular.md) and the palette: notification appearance is QML in `default/`, updated by a `git pull` and coloured by `Theme`, rather than a seeded file that no update reaches.

## Consequences

Notifications now share the shell's process. If Quickshell is down, nothing receives notifications -- there is no fallback daemon to step in -- and `notify-send` fails. That is the same trade [0006](0006-present-handaan-dialogs-as-part-of-the-desktop.md) made for dialogs, with `Restart=on-failure` on the unit the same mitigation. `handaan-notifications` says plainly when the shell is not running.

A fresh install has no mako: it is not in `install/desktop.packages` and there is no `config/mako` seed. Installed machines went in two steps. `migrations/1789334343.sh` masked `mako.service`, deliberately leaving a running mako alone so notifications kept working until the next login. `migrations/1789361075.sh` then uninstalls mako, removes the mask, and removes `~/.config/mako/config`, keeping an edited copy under `$HANDAAN_STATE/retired-config/` rather than deleting it.
