# ADR Changelog


## 2026-09-05 (handaan)

- **0003** and **0004** written together as part of the move from the `dots` dotfile repository to handaan. They are separable decisions — a tree that owns itself does not require migrations, and migrations would work under `rcm` — but each is half the answer to the same question: what is allowed to change on an installed machine, and by what mechanism.
- **0002** edited in place. The bootstrap now clones the tree to `$HANDAAN_PATH` and runs the installer out of it, rather than downloading two scripts to a temp directory. The `curl | bash` delivery and both guards it forced are unchanged.


## 2026-09-05

- **Records are now edited in place** rather than superseded, and this file was added. Supersession assumed a record described a moment; in practice each describes a standing question, and it is the answer that moves.
- **0002** written. The `curl | bash` delivery and the single dispatcher script are one decision, not two — `run_with_terminal` and the empty-file guard in `download` exist only because of the pipe.

## 2026-09-04

- **0001** written. GRUB, btrfs and Timeshift are one record rather than three: the requirement to boot a pre-upgrade snapshot forces all three, and separately each would read as an arbitrary preference.
