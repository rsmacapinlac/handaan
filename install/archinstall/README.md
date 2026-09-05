# archinstall profiles

Saved `archinstall` configurations and the live-ISO installer entry point.

`install.sh` is downloaded and launched by `setup/start.sh` on the Arch ISO. It
lists these profiles, shows the destructive device and hostname fields, requires
an explicit `yes`, and then runs Archinstall. `setup/arch.sh` does not run until
after the new system has booted with a normal sudo-capable user.

## Usage

Run the repository bootstrap from the live ISO:

```bash
curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash
```

Choose a saved profile or the interactive Archinstall option. Set credentials
interactively when prompted.

Do **not** reuse a saved `user_credentials.json`. It holds argon2id password
hashes, never belongs in this repo, and archinstall regenerates it on each run.

## Profiles

| file | machine | notes |
|---|---|---|
| `urakara.json` | ThinkPad T470s (LENOVO 20L8S0YW00) | GRUB, btrfs, `/dev/nvme0n1` |
| `vm-test.json` | libvirt VM, 30 GiB virtio disk | rehearsal target, `/dev/vda` |

### Testing a rebuild in a VM

`vm-test.json` exists so the bootstrap can be rehearsed without touching real
hardware. The repository is public, so the guest can fetch it directly from the
Arch ISO.

The full procedure — creating the VM, both bootstrap phases, snapshots, core
desktop validation, optional application groups, and teardown — is in
[`docs/testing-build-scripts.md`](../../docs/testing-build-scripts.md). How this profile
was adapted from `urakara.json` is under [vm-test.json](#vm-testjson) below.

## urakara.json

Captured from archinstall 3.0.9, verified against the running machine.

- **bootloader** GRUB, 1 GiB fat32 ESP at `/boot`
- **root** btrfs on `/dev/nvme0n1p2`, `compress=zstd`, subvolumes
  `@` → `/`, `@home` → `/home`, `@log` → `/var/log`, `@pkg` → `/var/cache/pacman/pkg`
  — see [Btrfs layout](#btrfs-layout)
- **snapshots** `snapshot_config` is `{"type": "Timeshift"}` in both profiles,
  and `setup/arch.sh` configures Timeshift again after the reboot. The two do
  different halves of the job — see [Btrfs layout](#btrfs-layout)
- **profile** `Minimal`, no greeter, no gfx driver, `packages: []` — the core
  desktop comes from `setup/arch.sh`; deferred software comes from
  `setup/applications.sh`
- **locale** `en_US.UTF-8`, `us` keymap, `America/Vancouver`, NTP on, swap on

### Hardware-bound values

These are specific to this laptop and must be reviewed before use elsewhere:

- `disk_config.device_modifications[0].device` — `/dev/nvme0n1`
- `...partitions[].size.value` — exact byte counts for a 931.5 GB drive
- `wipe: true` — **destroys the named device**; confirm the path first
- `hostname` — `urakara`

For a different machine, run `archinstall` interactively, save the config, and
add it here as a new file rather than editing this one.

## vm-test.json

`vm-test.json` is a worked example of that adaptation. It differs from
`urakara.json` in exactly four values — everything else, including the
subvolume layout, is identical:

| field | urakara | vm-test |
|---|---|---|
| `hostname` | `urakara` | `handaan-test` |
| `...device` | `/dev/nvme0n1` | `/dev/vda` |
| `...partitions[1].size.value` | `999128301568` | `31133270016` |
| `...partitions[].obj_id` | (this laptop's) | regenerated |

The ESP is untouched at 1 MiB start / 1 GiB size; only the root partition
depends on disk size. Sizing leaves 4 MiB at the end of the device for the
GPT secondary header.

The large `mirror_config` block is kept verbatim so this reproduces the original
install exactly. It can be trimmed to the region selection if it becomes noisy.

## Btrfs layout

Both profiles build the same filesystem, and `vm-test.json` exists partly to
rehearse it. The root partition is one btrfs filesystem carrying four
subvolumes, mounted flat rather than nested:

| subvolume | mountpoint | why it is split out |
|---|---|---|
| `@` | `/` | the subvolume a rollback actually reverts |
| `@home` | `/home` | so reverting `/` does not take your files back with it |
| `@log` | `/var/log` | keeps the logs that explain a bad upgrade from being reverted along with it |
| `@pkg` | `/var/cache/pacman/pkg` | large, re-downloadable, and worth nothing inside a snapshot |

The `@` naming is Ubuntu's convention rather than btrfs's own, and that choice
is load-bearing rather than cosmetic: Timeshift's BTRFS mode requires exactly
`@` and `@home` and will not run without them. Renaming the subvolumes would
cost the pre-upgrade snapshots silently, which is the failure mode worth
knowing about before editing a profile.

`/boot` is deliberately outside all of it. A fat32 ESP cannot be snapshotted,
and GRUB has to read it before any of this exists.

The profile asks only for `compress=zstd`. The installed system mounts
`compress=zstd:3,ssd,discard=async,space_cache=v2` — the level and the three
SSD options are defaults filled in below the profile, not values it sets, so
they will differ on non-SSD hardware and are not worth transcribing into a new
profile.

### Which half installs what

Snapshots are set up by two things that do not overlap, which is why neither
file alone explains the result.

**archinstall**, from `snapshot_config`. It acts on the field only when the
layout is `default_layout` with a btrfs partition (`is_default_btrfs`) — both
profiles qualify. With the type set to `Timeshift` and GRUB as the bootloader
it pacstraps `cronie` and `timeshift`, enables `cronie.service`, and, because
of GRUB, pacstraps `grub-btrfs` and `inotify-tools` and enables
`grub-btrfsd.service`, which is what puts snapshot entries in the boot menu. It
writes no Timeshift config, so nothing takes a snapshot yet.

**`setup/arch.sh`**, in `configure_timeshift`. It installs the
`timeshift-autosnap` pacman hook (which pulls in `timeshift`) and writes
`/etc/timeshift/timeshift.json` in BTRFS mode against the detected root UUID,
so `pacman -Syu` snapshots first. Scheduled snapshots stay off on purpose: the
goal is an escape hatch before an upgrade, not a backup rotation. It skips with
a warning if root is not btrfs, and leaves an existing config alone.

The archinstall behaviour above was read from the 3.0.9 source, which is the
version these profiles were captured from; Arch currently ships 4.4, so
re-verify before trusting it on a fresh ISO.

### This machine does not match its own profile

`urakara` was installed on 2026-08-31, after both profiles were committed, and
shows none of archinstall's half: `grub-btrfs` has never appeared in
`/var/log/pacman.log`, `grub-btrfsd.service` does not exist, and
`cronie.service` is disabled. The `timeshift` that is present arrived four
seconds before `timeshift-autosnap`, which is `arch.sh` installing it.

So on this machine the boot menu offers no snapshot entries and only the
pre-upgrade hook is live. Why the profile's half did not run is not recorded —
an interactive install rather than a saved profile would explain it. The next
rebuild from `vm-test.json` is the cheap place to find out, which is what that
profile is for.
