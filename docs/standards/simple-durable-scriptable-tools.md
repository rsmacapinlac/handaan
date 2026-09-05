# Simple, durable, scriptable tools

Choose simple, durable, scriptable tools over heavy integrated ones. Favour plain text configuration and local files.

This repository is the machine's recovery plan. Everything it holds has to survive a `git clone` onto a fresh install and mean the same thing afterwards. A tool whose configuration lives in a binary store, or behind a vendor account, cannot be restored that way — it can only be reconfigured by hand, which is the failure this whole tree exists to avoid.

Plain text has a second benefit that is easy to undervalue: the diff is reviewable. A change to a text config can be read, questioned and reverted. A change to an opaque blob can only be trusted.

This rules out configuration that exists only inside a GUI's preferences dialog, settings kept in a database the application owns, and anything that needs a network round-trip to reach its own defaults. Where a tool offers no plain-text path and is worth keeping anyway, record in `docs/` which part of its state this repository does not capture, so a rebuild knows what it still has to do by hand.
