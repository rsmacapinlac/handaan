# 0001. Recover from a bad upgrade by booting a pre-upgrade snapshot

Status: accepted

## Context

Arch is a rolling release, so `pacman -Syu` is the routine operation that can break the desktop. The potential failure is worth designing for.

A recovery path you can only reach *from* a working system is no help in exactly that case.

- Snapshots have to be automatic.
- A snapshot has to be accessible without a working system.

## Decision

Take a snapshot before every package upgrade, and make that snapshot bootable from the GRUB menu.

**Bootloader: GRUB.** Not systemd-boot — `grub-btrfs` is what writes snapshot entries into the boot menu, and archinstall installs it only for GRUB.

**Filesystem: btrfs** on the root partition, carrying four subvolumes mounted flat rather than nested:

| subvolume | mountpoint | why it is split out |
|---|---|---|
| `@` | `/` | the subvolume a rollback actually reverts |
| `@home` | `/home` | so reverting `/` does not take your files back with it |
| `@log` | `/var/log` | keeps the logs that explain a bad upgrade out of the rollback |
| `@pkg` | `/var/cache/pacman/pkg` | large, re-downloadable, worth nothing inside a snapshot |

`/boot` is a 1 GiB fat32 ESP, deliberately outside all of it.

**Packages, services, and config:**

| | installed by | does what |
|---|---|---|
| `grub` | archinstall | the bootloader the recovery path depends on |
| `grub-btrfs`, `inotify-tools` | archinstall, *because* the bootloader is GRUB | `grub-btrfsd.service` regenerates the boot menu so snapshots are bootable |
| `timeshift` | archinstall | takes and restores the snapshots |
| `cronie` | archinstall | enabled as `cronie.service`; every Timeshift schedule is off, so it does nothing for this |
| `timeshift-autosnap` | `install.sh` | pacman PreTransaction hook — snapshots before every `pacman -Syu` |
| `/etc/timeshift/timeshift.json` | `install.sh` | BTRFS mode against the detected root UUID; without it Timeshift does nothing |

**Snapshot policy**, saved to `/etc/timeshift/timeshift.json`:

| field | value | effect |
|---|---|---|
| `btrfs_mode` | `true` | snapshots are btrfs subvolumes |
| `schedule_monthly` … `schedule_boot` (all five) | `false` | snapshots happen only on an upgrade |
| `include_btrfs_home_for_backup` | `false` | `/home` is never snapshotted |
| `include_btrfs_home_for_restore` | `false` | …and is never reverted by a restore |
| `do_first_run` | `false` | no snapshot at install time |

This protects the system, not your data. There is no retention policy, no second copy, and nothing offsite.
