# Core applications list stays minimal

Core applications are installed by default and should be carefully chosen.

Something belongs in core only if the desktop is unusable without it — a compositor, a bar, a terminal, a launcher, notifications — or if configuring it later is meaningfully harder than configuring it during bootstrap. 

Account-bound services are never core. They live in `bin/handaan-service-*` and are kept out of the bootstrap on purpose, because they cannot complete without someone logging in to an account and would turn an unattended rebuild into an interactive one.

The same split applies to `.desktop` overrides. `applications/*.desktop` is seeded into `~/.local/share/applications` by core's `seed-config.sh`, so anything there must belong to a package core actually installs. An override for an optional package (one installed by `handaan-apps`) goes in `applications/optional/` instead, and is copied by that package's install group in `bin/handaan-apps` -- otherwise a core-only install ends up with a launcher for a binary that was never installed.

