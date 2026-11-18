# Rail Terminal tooltip with hotkey (#39, criterion 7)

The Rail Terminal tooltip shows "Terminal" plus the hotkey, and follows a changed hotkey.

Status: pending

## Sub-features

- `39-7-default` help text "Terminal" plus ⌃⌥T (exact: "Terminal  ⌃⌥T", two spaces, same format as Slot tooltips "name  ⌘1").
- `39-7-follows` after recording a new hotkey the tooltip changes.
- `39-7-cleared` with the hotkey cleared, the tooltip is "Terminal".

## How to get to it (user POV)

- Hover the Terminal icon in the Rail.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Default.** `oc get-app-state --query Terminal`: the Rail button's help is `Terminal  ⌃⌥T`.
- **Follows.** Change the hotkey (terminal-39-6), re-read the help text: new combination, no relaunch.
- **Cleared.** Clear the recorder (its x button), re-read: `Terminal`.
- **Proof.** tree excerpts saved to `<run>/evidence/39-7-*.txt`.

## Gotchas

- The Rail is rebuilt on settings changes and on `KeyboardShortcuts_shortcutByNameDidChange` (PanelController observes it); a stale tooltip after recording is a real bug, not a harness issue.
