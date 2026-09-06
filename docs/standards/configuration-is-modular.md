# Configuration is modular

Application configuration lives under `config/<app>/` when it is yours to edit, and `default/<app>/` when it is handaan's. Commands live in `bin/`. Installer steps live in `install/<phase>/`.

Layout here is not organisation, it is interface — but the interface is *ownership*, not deploy order. Where a file sits says who may edit it and what an update is allowed to do to it:

- `default/` is read live out of `$HANDAAN_PATH`. A `git pull` changes it under a running system, which is exactly what should happen to a default. Never edit these on a machine; the edit is either lost or silently diverges from the repository it came from.
- `config/` is a seed. It is copied into `~/.config` once at install and never again, so what you write there survives every update. `handaan-refresh-config` takes a newer default deliberately, `handaan-diff-config` shows what has drifted, and `handaan-promote-config` sends a good local edit back into the tree.

The same argument applies inside an application. Keep concerns in separate modules — `default/hypr/`, `default/quickshell/modules/` — so a change touches one file and a reader looking for one behaviour finds one place. Splitting also decides how much an override costs: `~/.config/hypr/conf/local.lua` can replace one setting precisely because the defaults are loaded as separate modules that it runs after.

Deciding which tree a file belongs in is the same question every time: **would a `git pull` be allowed to change this file under you?** If yes it is a default; if no it is a seed.

[Privacy](privacy-policy.md) covers which of the two *repositories* a new file belongs in, which is a separate question from this one.
