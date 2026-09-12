# Testing the build scripts

The rebuild has a live-ISO Archinstall phase, a post-reboot core phase, and
optional application groups installed from the finished Hyprland desktop. Many
core steps only execute on a fresh machine, so a disposable VM is the only way
to exercise the complete path.

`install/archinstall/vm-test.json` targets a 30 GiB virtio disk and is structurally identical to the real machine's profile apart from the device, disk size and hostname.

30 GiB is sized from a measured run, not guessed: the core phase uses about
6 GB, and `applications.sh all` takes it to **16 GB** — and that figure is
optimistic, since it was measured with a freshly cleared package cache and
before Timeshift snapshots had accumulated. Leave headroom for both, plus the
slack btrfs wants to avoid behaving badly when near-full.

**Changing the size means changing two things.** The `--disk size=` below and
`partitions[1].size.value` in `vm-test.json` must agree, or Archinstall tries to
create a partition larger than the disk and fails at partitioning. The profile
value is the disk size minus the 1 GiB ESP start offset (`1074790400`) minus
4 MiB for the GPT backup header — for 30 GiB that is `31133270016`.

You *must*:
- Test as if you're the user. Send keys to the virtual machine as a user would with a keyboard.
- Show the virtual machine using the viewer, so the work can be monitored by a human.

## Local checks before the VM

Run the cheap checks first. They catch syntax and console-key mapping failures
without spending time on a rebuild:

```bash
bash -n boot.sh install.sh install/lib/*.sh install/*/*.sh \
  install/archinstall/install.sh bin/* test/vm-send-keys test/*.sh
luac -p config/hypr/hyprland.lua config/hypr/conf/*.lua default/hypr/*.lua
jq empty install/archinstall/urakara.json install/archinstall/vm-test.json
test/vm-send-keys-test.sh
```

Cursor's `keybindings.json` is JSONC, not strict JSON, and must not be passed to
`jq` without removing its comments first.

`shellcheck` on the same shell scripts catches what `bash -n` cannot — quoting,
unused variables, and the subshell mistakes that only bite at runtime. Use
`sh -n` rather than `bash -n` for anything with a POSIX `sh` shebang.

The bar has its own load test, and it is worth running on any QML change:

```bash
qs -n -p default/quickshell        # expect: Configuration Loaded, no warnings
```

`QT_QPA_PLATFORM=offscreen` catches every parse and type error without drawing
on the live session. It still fails at `No PanelWindow backend loaded`, because
layer-shell needs real Wayland — reaching *that* error means the QML itself is
sound. In a running session, confirm the surfaces actually map:

```bash
hyprctl layers | grep quickshell
```

Hyprland is the one that punishes a syntax-only check. `luac -p` validates Lua
grammar, not `hl.*` arguments, and **bad binds and rules fail silently at
load** — nothing appears in the log. After a reload, always:

```bash
hyprctl configerrors   # Lua errors surface here, not in the log
hyprctl binds          # verify modmasks after touching conf/binds.lua
hyprctl monitors
```

Run `hyprctl reload` only when the live session is meant to be reloaded.

Validate strict JSON with `python -m json.tool`, never JSONC; parse YAML with
whatever tooling is installed.

Confirm that the VM profile still matches the documented 30 GiB disk geometry:

```bash
test "$(jq -r '.disk_config.device_modifications[0].partitions[1].size.value' \
  install/archinstall/vm-test.json)" = 31133270016
```

The host virtualization stack comes from the optional application group. Run
this once on the host, then log out and back in for `kvm` and `libvirt` group
membership to take effect:

```bash
handaan apps-install virtualization
```

Before creating a guest, verify the exact capabilities used below:

```bash
virt-host-validate qemu
systemctl is-active libvirtd virtlogd virtlockd
virsh --connect qemu:///system net-info default
virsh --connect qemu:///system domcapabilities --virttype kvm
```

Hardware virtualization, `/dev/kvm`, `/dev/vhost-net`, `/dev/net/tun`, the
libvirt services, the active/autostarting default network, KVM domain support,
and an OVMF loader must all be present. IOMMU and secure-guest warnings do not
block this ordinary VM; they matter for device passthrough or confidential
guests.

## Creating the VM

```bash
# The ISO is ~1.5 GiB — keep it outside the repo, and off /tmp.
# /tmp is tmpfs here, so an ISO parked there is 1.5 GiB of RAM the 4 GiB guest
# then has to compete for. /var/tmp is on disk.
mkdir -p /var/tmp/handaan-vm
curl -o /var/tmp/handaan-vm/archlinux-x86_64.iso \
  https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso

# Verify it. A truncated or corrupt ISO wastes a full rehearsal before it fails.
curl -fsSL -o /var/tmp/handaan-vm/sha256sums.txt \
  https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt
grep 'archlinux-x86_64.iso$' /var/tmp/handaan-vm/sha256sums.txt \
  | sed 's#archlinux-x86_64.iso#/var/tmp/handaan-vm/archlinux-x86_64.iso#' | sha256sum -c -

virt-install --connect qemu:///system \
  --name handaan-test --memory 4096 --vcpus 4 --cpu host-passthrough \
  --disk path=/var/lib/libvirt/images/handaan-test.qcow2,size=30,bus=virtio,format=qcow2 \
  --boot uefi --cdrom /var/tmp/handaan-vm/archlinux-x86_64.iso --os-variant archlinux \
  --graphics spice --video virtio
```

4096 is enough for ```--memory```.

```
kernel: CPU 3/KVM invoked oom-killer
kernel: Out of memory: Killed process (qemu-system-x86) anon-rss:7283352kB
```
`--boot uefi` matters: `/boot` is an ESP, and a BIOS guest exercises a different
path. `--cpu host-passthrough` exposes VMX so the virtualization steps actually
run. `virt-viewer` must be installed for a usable console.

The VM lives on the system connection, not the session one. Export this or every
`virsh` call needs `--connect qemu:///system`:

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
```

## Running it

Type the bootstrap **at the VM console**.

```bash
curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash
```

In the archinstall menu you **must** set a root password and add a user **with sudo/wheel** — the profile deliberately carries no credentials. From the main menu that is:

1. **Authentication** (9th item) → **Root password**, typed twice.
2. **User account** → **Add a user** → username, password twice, then **"Should <user> be a superuser (sudo)?" → Yes** (already highlighted). Then **Confirm and exit**, then **Back**.
3. **Install** (below the blank line, above Abort). The right pane must read `Ready to install`.

**Selecting Install is not the last confirmation.** archinstall then shows *"The specified configuration will be applied. Would you like to continue?"* over a full JSON dump of the config, with **Yes** preselected. An unattended run that stops watching after pressing Install will sit on this dialog forever looking exactly like a slow pacstrap. Press Enter again.

That JSON is worth reading rather than skipping — it is the only place the whole resolved configuration appears at once. Confirm `"bootloader": "Grub"` and the fat32 `/boot` ESP, which is what [ADR 0001](decisions/adrs/0001-system-upgrade-snapshots-and-rollback.md) depends on.

## Snapshot before the core phase

Install `qemu-guest-agent` before taking the snapshot. 

```bash
virsh destroy handaan-test                              # the ISO ignores ACPI shutdown
virsh change-media handaan-test sda --eject --config    # or it boots the installer again
virsh start handaan-test
```

When the guest was created with `virt-install --cdrom`, libvirt has already
dropped the media from the *persistent* definition, so the eject above answers
`error: The disk device 'sda' doesn't have media`. That is the expected result
in this path, not a problem — run it anyway, because a guest created any other
way will still be holding the ISO and will cheerfully reinstall.

`virt-viewer` exits when the domain is destroyed. Start it with `--reconnect`
so it survives the eject cycle and the reboots that follow, or you will be
running blind exactly when the interesting part starts.

Then, at the guest console, log in and install the agent:

```bash
sudo pacman -Sy --noconfirm qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

`systemctl` warns that the unit has no install config; that is expected, since it is udev-activated. Confirm it came up with `guest-ping` from the host, then snapshot:

> **Check the unit file, not just `guest-ping`.** Because the agent is
> udev-activated, `qemu-ga` can be running while its systemd unit is unusable —
> so `guest-ping` succeeds and the agent still disappears after the core phase's
> daemon-reloads and the next reboot. This has happened: a corrupt download left
> `/usr/lib/systemd/system/qemu-guest-agent.service` at **0 bytes**, which
> systemd treats as *masked*. Verify both:
>
> ```bash
> test -s /usr/lib/systemd/system/qemu-guest-agent.service && echo unit-ok
> systemctl is-active qemu-guest-agent          # expect: active
> ```
>
> If the unit is empty, the cached package is corrupt. Clear it and reinstall:
>
> ```bash
> sudo find /var/cache/pacman/pkg -name '*.pkg.tar.zst' -delete
> sudo pacman -Sy --noconfirm --overwrite '/usr/*' qemu-guest-agent
> ```

```bash
virsh qemu-agent-command handaan-test '{"execute":"guest-ping"}'   # => {"return":{}}

virsh destroy handaan-test
virsh snapshot-create-as handaan-test clean-install "post-archinstall, agent, pre-bootstrap"
virsh start handaan-test

# after a failed attempt
virsh snapshot-revert handaan-test clean-install
```

Eject while the domain is stopped. `--config` alone edits the persistent
definition and leaves a running domain untouched.

Because the snapshot is taken with the domain shut off, a revert boots with an
empty `/run` and therefore no cached sudo credential, so `check_sudo` prompts
for real. That only stops being true if the agent is installed in the *same*
session as the bootstrap: `sudo` caches a credential for five minutes, which
silently satisfies `check_sudo` and leaves its password prompt untested. Run
`sudo -k` first in that case.

## Testing a branch

Test a branch without merging to `main`:

```bash
HANDAAN_REF=my-branch bash -c 'curl -fsSL \
  https://raw.githubusercontent.com/rsmacapinlac/handaan/my-branch/boot.sh | bash'
```

Both provisioning scripts are idempotent. After correcting a failure, rerun the
whole relevant entry point: `boot.sh` for core provisioning or
`handaan apps-install <name>` for an optional application. There is intentionally no
public single-function recovery interface.

Note that `raw.githubusercontent.com` caches for around five minutes, so a freshly pushed commit is not immediately visible to the guest. The GitHub API serves the current content without that delay:

```bash
curl -fsSL -H 'Accept: application/vnd.github.raw' -o /tmp/start.sh \
  'https://api.github.com/repos/rsmacapinlac/handaan/contents/boot.sh?ref=main'
```

## Driving it from the host

The console can be operated without touching the VM window, which is useful for scripted or unattended rehearsals.

```bash
virsh screenshot handaan-test console.ppm               # read the screen
magick console.ppm console.png                          # ImageMagick 7: magick, not convert
virsh send-key handaan-test --codeset linux KEY_ENTER   # type at the console
```

`virsh screenshot` writes a **PPM** regardless of the extension you give it, so
naming the target `.png` produces a PPM with a misleading name that most viewers
will still open and some tools will not. Convert it explicitly.

Use the repository helper for text. It sends one paced event per character so
repeated letters are not collapsed, handles shifted US-keyboard punctuation,
and can press Enter after the text. Focus the intended terminal or input field
in the viewer first; libvirt sends keys to whichever guest window has focus:

```bash
test/vm-send-keys --enter handaan-test 'bash /tmp/boot.sh'
test/vm-send-keys --prompt --enter handaan-test       # passwords, hidden input
test/vm-send-keys --dry-run --enter handaan-test 'echo test'
```

Use `virsh send-key` directly for standalone control keys such as `KEY_ESC`.
The helper's mappings can be checked without a VM using
`test/vm-send-keys-test.sh`.

For a live smoke test, focus a guest terminal in the viewer and send a harmless
command whose exact output is easy to recognize:

```bash
test/vm-send-keys --enter handaan-test 'printf vm-key-test'
```

The Arch ISO also runs `qemu-guest-agent`, so commands can be run in the *live* environment directly — handy for staging files before typing:

```bash
virsh qemu-agent-command handaan-test \
  '{"execute":"guest-exec","arguments":{"path":"/bin/sh","arg":["-c","..."],"capture-output":true}}'
```

That only works on the ISO. The installed system has no guest agent of its own,
so without one the console is the only way in after the first reboot — which
makes diagnosing a late core failure painful, since a framebuffer screenshot
shows about 25 lines at a time. Installing it into the baseline is covered in
[Snapshot before the core phase](#snapshot-before-the-core-phase).

With the agent running, the console can be read as text rather than pixels,
which beats cropping screenshots:

```bash
virsh qemu-agent-command handaan-test \
  '{"execute":"guest-exec","arguments":{"path":"/bin/sh","arg":["-c","fold -w 160 /dev/vcs1"],"capture-output":true}}'
```

**`/dev/vcs1` is NUL-padded, and that silently breaks `grep`.** A screen read
this way is mostly `\0`, so `grep` decides the input is binary, prints
`Binary file (standard input) matches` and *suppresses the matching line*. With
`-q` it still returns 0 — so a polling loop that greps for a completion string
matches immediately and reports success against a screen that says nothing of
the kind. This has happened: a watcher for the end of the base install returned
at once while archinstall was still sitting on its confirmation dialog. Strip
them first:

```bash
... | tr -d '\0' | grep -aiE 'installation completed|traceback'
```

Make the failure branch as wide as the success branch while you are there. A
watcher that greps only for the success string stays silent through a crash, a
hang, and a prompt waiting on input — and silence looks exactly like "still
working".

And pick a success string that appears **only** in the state you are waiting
for. Watching for `chroot` to detect the end of the base install matches
`Skipped: Running in chroot.` — which pacstrap prints repeatedly, minutes early,
while it is still installing packages. The watcher then reports done against a
half-built system. Anchor on the full sentence archinstall actually prints, not
on a word that also occurs in ordinary log output.

**Do not try to detect a stalled prompt by grepping for prompt text.** An
answered prompt stays on the screen, so `:: Proceed with installation? [Y/n]`
from a `--noconfirm` transaction reads exactly like a live one that nobody is
answering. The reliable signal is that the screen *stops changing*: hash the
console read each poll and alarm after N identical results.

```bash
h=$(md5sum <<<"$txt" | cut -d' ' -f1)
[[ $h == "$prev" ]] && same=$((same+1)) || same=0
prev=$h
(( same >= 12 )) && { echo "unchanged for ~3min — likely stalled"; exit 3; }
```

All three of these — the too-broad success string, the NUL padding, and the
answered-prompt false positive — are the same mistake: treating a console
*scrollback buffer* as if it were an event stream. It is a picture of the last
N bytes, with no notion of when any of it happened.


Note that the agent runs as root and bypasses the console entirely, so use it to
*verify* results, never to drive `start.sh` — driving it from anywhere but the
console is what hides terminal-handling bugs.

## Verify the desktop and optional installer

After the core phase succeeds, reboot and confirm greetd starts Hyprland for the
user. Run the checks in [`arch-vm-validation.md`](arch-vm-validation.md), then
exercise the optional interface before installing packages:

```bash
handaan apps-install --help
handaan apps-install not-an-app    # must fail before sudo or an upgrade
handaan apps-manifest              # catalogue as JSON; no session needed
handaan apps                       # open the installer, cancel with Escape
```

For a complete optional-application rehearsal, install every group and then run
the same command again to exercise idempotency:

```bash
handaan apps-install all
handaan apps-install all
```

Each invocation must perform one full system upgrade. The second run should
skip current packages, complete without errors, clean temporary build
dependencies, and remove the temporary passwordless sudo rule.

The Citrix payload is too large to build in the VM's memory-backed `/tmp`.
`install_citrix` deliberately uses disk-backed `/var/tmp`; a regression here
fails during `package()` with `Disk quota exceeded` even when the btrfs disk has
plenty of free space. After `all` completes, verify the fix and the final
service state:

```bash
pacman -Q icaclient syncthing
systemctl --user is-enabled syncthing.service
systemctl --user is-active syncthing.service
find /var/tmp -maxdepth 1 -name 'handaan-icaclient.*' -print  # expect no output
systemctl --user list-units --state=failed                # expect none
```

## What a VM will not tell you

Hyprland and greetd do come up on software rendering, but a VM has no real GPU,
so failures there usually mean the VM rather than the configuration. `battery`
is absent, which is worth knowing when checking Waybar styling. Hardware checks
must remain vendor-neutral. Steam and virtualization are optional, large
downloads and should be validated separately from the core rehearsal.

**EGL does not work in this VM, and that has teeth.** `eglInitialize` fails
(`EGL_NOT_INITIALIZED`, `DRI2: failed to create screen`), Mesa falls back to
`kms_swrast`, and that fallback wants DRM dumb buffers on the card instead of
the render node — which the compositor already holds as DRM master. Anything
using EGL therefore dies with `DRM_IOCTL_MODE_CREATE_DUMB failed: Permission
denied`. `hyprpaper` is the visible casualty: it exits, and the session falls
back to Hyprland's built-in background.

Three graphics configurations were tried, and all fail the same way. Do not
spend time on this again:

| Config | Result |
|---|---|
| No acceleration (the `virt-install` above) | EGL fails immediately; `hyprpaper` never starts |
| `--video ...accel3d=yes` + `--graphics egl-headless` | `hyprpaper` starts, dies on render |
| spice GL + virgl as the sole GL display | `hyprpaper` starts, dies on render |

The signature is precise and identical each time:

```
hyprctl hyprpaper listactive   → ipc=0                    # healthy
set_wallpaper --initial        → exit 0                   # "succeeds"
hyprctl hyprpaper listactive   → wire handshake failed    # now dead
```

`hyprpaper` idles happily and dies the moment it has to *render* an image, on
GBM buffer allocation. Ruled out along the way, each by direct check rather
than inference:

- **Environment** — uwsm finalizes correctly; `systemctl --user show-environment`
  carries `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE` and friends.
- **Permissions** — `getfacl /dev/dri/card*` shows the logind seat ACL granting
  the user `rw`.
- **A startup race** — it dies even when `hyprpaper` is fully up and answering
  IPC first.

Notes if you try anyway: spice GL needs a *local socket* listen, which
disconnects `virt-viewer` (`spice://127.0.0.1:5900` stops working) — revert
`<listen type='address'/>` to get the viewer back. QEMU also refuses more than
one OpenGL display, so `egl-headless` and spice GL are mutually exclusive.

So: **wallpaper and any other GPU-dependent behaviour cannot be validated in
this VM.** Verify those on real hardware, and do not record a VM failure of
that kind as a configuration defect.

Unrelated to the GPU and worth fixing on its own: `set_wallpaper` returns exit
0 when the IPC wait loop times out, so a dead `hyprpaper` produces no wallpaper
and no error.

## Tearing it down

```bash
virsh destroy handaan-test
virsh undefine handaan-test --nvram --remove-all-storage \
  --snapshots-metadata                                 # --nvram: the VM is UEFI
```

`--snapshots-metadata` is required once `clean-install` exists; without it
`undefine` refuses with "cannot delete inactive domain with 1 snapshots".

## See also

- [`install/archinstall/README.md`](../install/archinstall/README.md) — how
  `vm-test.json` was derived from the real machine's profile, and which values
  are hardware-bound.
