# Cmd+A selects the whole scrollback (#45, criterion 3)

`Cmd+A` selects the tab's whole scrollback, not just the screen.

Status: pending

## Sub-features

- `45-3-all` after `seq 1 300`, `Cmd+A` then `Cmd+C` copies lines 1 to 300.

## How to get to it (user POV)

- `Cmd+A`, then `Cmd+C`.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`; back up the clipboard.

- **Select and copy.** Type `seq 1 300` + Return, `oc hotkey --key CmdOrCtrl+A`, `oc hotkey --key CmdOrCtrl+C`. `pbpaste | grep -c '^[0-9]*$'` ≥ 300 and `pbpaste | head` contains `1`.
- **Restore.** `pbcopy < <run>/clipboard.bak`.

## Gotchas

- Depends on terminal-45-1 (`Cmd+C`) working.
- Built: SwiftTerm's `selectAll:` via the hidden Edit menu; any key press clears the selection, so send `Cmd+C` right after `Cmd+A`.
