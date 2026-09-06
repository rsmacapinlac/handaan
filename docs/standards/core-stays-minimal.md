# Core applications list stays minimal

Core applications are installed by default and should be carefully chosen.

Something belongs in core only if the desktop is unusable without it — a compositor, a bar, a terminal, a launcher, notifications — or if configuring it later is meaningfully harder than configuring it during bootstrap. 

Account-bound services are never core. They live in `bin/handaan-service-*` and are kept out of the bootstrap on purpose, because they cannot complete without someone logging in to an account and would turn an unattended rebuild into an interactive one.

The same split applies to `.desktop` overrides. `applications/*.desktop` is seeded into `~/.local/share/applications` by core's `seed-config.sh`, so anything there must belong to a package core actually installs. An override for an optional application doesn't belong in this repository at all -- handaan ships no optional applications of its own (see [0005](../decisions/adrs/0005-accept-user-owned-optional-applications.md)); it lives in that app's own `config/` directory, wherever the app itself is defined.

