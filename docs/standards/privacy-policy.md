# Privacy: what belongs in the public tree

This repository is public and holds defaults. Configuration that contains personally identifiable information should be kept out.

A user of handaan should have their own private repository to keep configuration and information separate.

Identities and user preferences / configuration should not be part of this repository.

## Rules

- Do not add secrets, tokens, private keys, passwords, or local-only network share details.
- Internal hostnames are covered by that rule. Do not commit anything under a private domain, including in browser bookmarks, docs, or example configs.
- Be careful with files under `gnupg/`, mail configs, SSH/GPG setup sections, and setup scripts that copy sensitive material.
- Tracked build artifacts can outlive the source they came from. A `.pyc` kept both hostnames as string constants after `config.py` was cleaned, and `.gitignore` does not untrack what git already tracks.
