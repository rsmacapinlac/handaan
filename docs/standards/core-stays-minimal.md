# Core applications list stays minimal

Core applications are installed by default and should be carefully chosen.

Something belongs in core only if the desktop is unusable without it — a compositor, a bar, a terminal, a launcher, notifications — or if configuring it later is meaningfully harder than configuring it during bootstrap. 

Account-bound services are never core. They live in `bin/handaan-service-*` and are kept out of the bootstrap on purpose, because they cannot complete without someone logging in to an account and would turn an unattended rebuild into an interactive one.

