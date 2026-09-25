# Update indicator

Purpose: Tells the user whether anything on this machine is waiting to be updated.

Notes:

- States for this widget:
  - Security updates waiting
    - Pulse the critical icon
    - Display of packages should say "[x] Security updates"
  - Package updates waiting
    - Icon should be regular icon (grey?)
    - Display should be a roll up of all package updates + handaan updates +
      migrations.
  - Handaan updates needed
    - Icon should be regular icon (grey?)
    - Display should be a roll up of all package updates + handaan updates +
      migrations.
  - Migrations required.
    - Icon should be regular icon (grey?)
    - Display should be a roll up of all package updates + handaan updates +
      migrations.
- Tooltip should always show the break down of what needs updating.
- Apps from the user's catalog (`handaan apps`) the user has not installed are not included as updates.
- A check that could not run is not the same as nothing to do. An unmeasured source reports -1 rather than 0, and the widget refuses to appear on the strength of an unknown — a missing `checkupdates`, or a fetch that failed before the network was up, would otherwise light the bar on every boot. When the card is up for other reasons the tooltip says which check is blind, rather than quietly undercounting.
- The counts are polled once for the process rather than once per monitor, and every bar is a view onto that one half-hourly run of `handaan-pending --fetch`. `handaan update` re-polls it on its way out, so the bar is not stale for half an hour after the work is already done.
- Arriving fades in over a beat. That is a transition rather than motion — bounded, over before you look at it, and there to make the arrival legible as a change rather than a glyph that was always there and you had missed.
- The first few seconds after login are not that state. Every count is still unknown then, and the card should wait for a poll to complete rather than displaying zeros.

Extra Information:

- How many are waiting, then what of: Security updates waiting,  package updates, handaan commits, migrations. A source with nothing waiting gets no line, because "0 packages" is noise on a layer that exists to be precise.
- "Could not check", naming the source, when a check could not run.

