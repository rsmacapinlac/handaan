# Automation is rerunnable and explains itself

Setup and maintenance scripts must be safe to rerun, and must say what they are doing while they run.

Both halves come from the same observation: these scripts are rerun far more often than they are run. A bootstrap fails partway and gets retried. A package is added and the installer runs again over an already-configured machine. A VM rehearsal runs the optional installer twice on purpose to prove idempotency — see [Testing the build scripts](../testing-build-scripts.md).

So a script checks before it creates, guards what is already installed, and can be re-entered at any point without repairing the damage from the last attempt. Where a step genuinely cannot be repeated, it says so and skips.

The second half matters because a long bootstrap that prints nothing is indistinguishable from one that has hung. Announce each phase through the logging helpers rather than bare `echo`; [Code style](../code-style.md) covers `log_info`, `log_success`, `log_warning` and `log_error` and the form they take.

Prefer several understandable steps that can each be rerun to one large script that must succeed as a whole.
