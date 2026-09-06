# 0004. Apply changes to already-installed machines without rerunning the installer

Status: accepted

## Context

`git pull` updates files in the tree. It cannot enable a systemd unit, write to `/etc`, remove a package that was replaced, or repoint a path that an installed machine still holds.

The old answer was to rerun the whole installer. It is idempotent, so this was safe — but it is also slow, it re-evaluates every decision to reach the one that changed, and it makes every past fix a permanent branch in the installer. The `ksshaskpass` and `polkit-gnome` removals exist because of an authentication-agent conflict on machines that once had them; a fresh install has never seen either. That is a one-time repair living forever in the code path of an install that does not need it.

## Decision

Ship one-shot repairs as **migrations**: `migrations/<unix-timestamp>.sh`, run per-machine by `handaan-migrate`, with completion recorded as an empty marker in `~/.local/state/handaan/migrations/`.

- **The timestamp is the ordering.** Take it from the last commit, so the name sorts by when the change landed rather than by when someone got round to writing the fix.
- **A fresh install marks every migration as already applied.** `install/preflight/migrations.sh` touches all the markers before anything else runs. A machine built from this checkout already has what the migrations were written to repair; replaying them would at best waste time and at worst undo something the current installer does correctly.
- **A migration must be idempotent and must explain itself**, opening with an `echo` of what it is doing and why. It is read most often by someone watching it run on a machine they are trying to fix.
- **A failure is a question, not a crash.** `handaan-migrate` offers to skip and continue, recording the choice in `migrations/skipped/` so the answer sticks. A migration that fails silently, or that wedges every future update, is worse than one that is skipped on purpose.
- **`handaan-update` runs them after the package transaction and before the tool updates** — a migration usually exists to repair something a new package version needs, and anything downstream should see the repaired state.

## Consequences

Migrations are the only mechanism that reaches an installed machine, so a change that touches system state is not finished until either the installer handles the fresh case *and* a migration handles the installed one, or the change is provably irrelevant to existing machines.

This creates a test case that neither a syntax check nor a fresh-install VM rehearsal covers: install an older ref, `git pull` to HEAD, run `handaan-migrate`. It is the only way to find a migration that is wrong, and it belongs in the rehearsal alongside the bare-ISO run. See [Testing the build scripts](../../testing-build-scripts.md).
