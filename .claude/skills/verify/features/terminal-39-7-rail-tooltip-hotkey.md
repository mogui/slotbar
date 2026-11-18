# Rail Terminal tooltip with hotkey (#39, criterion 7)

The Rail Terminal tooltip shows "Terminal" plus the hotkey, and follows a changed hotkey.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence - user-reported (observed by the user, no recorded artifact)

## Sub-features

- `39-7-default` help text "Terminal" plus ⌃⌥T (exact: "Terminal  ⌃⌥T", two spaces, same format as Slot tooltips "name  ⌘1").
- `39-7-follows` after recording a new hotkey the tooltip changes.
- `39-7-cleared` with the hotkey cleared, the tooltip is "Terminal".

## How to get to it (user POV)

- Hover the Terminal icon in the Rail.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Default.** User step: the user hovers the Terminal icon and reads `Terminal  ⌃⌥T` (the `orca computer` tree carries no help text; RailItemsTests `terminalTooltip*` cover the string).
- **Follows.** Change the hotkey (terminal-39-6), the user hovers again: new combination, no relaunch.
- **Cleared.** Clear the recorder (its x button), the user hovers again: `Terminal`.
- **Proof.** the user's report of each tooltip, `defaults read io.github.mogui.slotbar.verify KeyboardShortcuts_toggleTerminal` after each change.

## Gotchas

- The Rail is rebuilt on settings changes and on `KeyboardShortcuts_shortcutByNameDidChange` (PanelController observes it); a stale tooltip after recording is a real bug, not a harness issue.
