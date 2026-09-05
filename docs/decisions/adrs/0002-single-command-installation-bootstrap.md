# 0002. Bootstrap the installation with a single command, run once per phase

Status: accepted

## Context

A rebuild starts from a bare Arch ISO and a working internet connection.

- One command should be enough to memorise.
- It has to work before anything from this repository exists on disk.
- It has to be rehearsable in a VM, against a branch.

## Decision

One entry point, fetched and piped to bash:

```bash
curl -fsSL https://raw.githubusercontent.com/rsmacapinlac/handaan/main/boot.sh | bash
```

`boot.sh` installs nothing. It is a dispatcher: it works out which phase the machine is in and hands off.

The two phases hand off differently, and the asymmetry is deliberate. The live-ISO phase downloads one script to a temp directory, because nothing is meant to survive the ISO. The installed-system phase **clones the whole tree to `$HANDAAN_PATH` and runs `install.sh` out of it**, because that checkout is not a build artifact — it is where handaan lives afterwards, and every path in the installed system resolves back into it (see [0003](0003-install-into-a-single-owned-tree.md)).

**Phase detection**:

| signal | phase |
|---|---|
| `HANDAAN_FORCE_PHASE=iso` or `=system` | forced — for VM rehearsals |
| `/run/archiso` exists | live ISO |
| `/etc/hostname` is `archiso` | live ISO |
| otherwise | installed system |

**What each phase does:**

| phase | requires | downloads | runs |
|---|---|---|---|
| live ISO | root | downloads `install/archinstall/install.sh` | starts archinstall profile selection or archinstall itself, then reboot |
| installed | non-root, with `sudo` | clones the repository to `$HANDAAN_PATH` | runs `install.sh` from the checkout, then reboot |

Both privilege checks are explicit and fatal: the ISO phase refuses to run as non-root, the core phase refuses to run as root and pre-authenticates with `sudo -v`.

**Everything is environment-overridable** — `HANDAAN_REPO`, `HANDAAN_REF`, `HANDAAN_PATH`, and `ARCHINSTALL_URL`. A VM rehearsal runs a branch with `HANDAAN_REF=<branch> curl … | bash`.

**Two guards exist only because of the pipe:**

- `run_with_terminal` reopens `/dev/tty` for the downstream script. Piping to bash makes stdin the pipe, so a prompt in `install.sh` or `arch.sh` would otherwise read the script's own remaining text, or fail outright.
- `download` fails on a non-zero curl exit *and* on a zero-byte result, because a truncated fetch is otherwise indistinguishable from an empty script that runs and succeeds.

**The fetch is unauthenticated and unpinned.** It resolves `main` at the moment it runs. `HANDAAN_REF` can pin a tag or commit; the command in `README.md` does not use it. The repository must also stay public — there are no credentials on a live ISO to authenticate with.

**A failed install phase leaves the checkout in place** and prints the path, so it can be read, fixed and rerun with `bash install.sh` — no re-download, and no second copy to get out of sync with. An existing checkout is never destroyed: it may hold unpushed work, since it is also where handaan is developed.
