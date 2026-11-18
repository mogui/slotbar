# Shell exit closes its tab (#40, criterion 4)

A shell exit (`exit`, `Ctrl+D`) closes its tab; on the last tab it is replaced by a fresh shell and the Panel stays shown.

Status: pending

## Sub-features

- `40-4-exit` with two tabs, `exit` in one closes it.
- `40-4-ctrl-d` `Ctrl+D` behaves the same.
- `40-4-last` `exit` on the last tab respawns, Panel still shown.

## How to get to it (user POV)

- Type `exit` or press `Ctrl+D`.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Exit with two tabs.** `Cmd+T`, type `exit` + Return. `V shells`: 1; Panel shown.
- **Ctrl+D.** `Cmd+T`, `oc hotkey --key Control+D`. `V shells`: 1.
- **Last.** type `exit` + Return. `V doctor`: Panel still shown; `V shells`: one shell, new pid; `V logs`: `Shell exited` then `Spawning`.

## Gotchas

- `oc hotkey` uses `CmdOrCtrl` for Cmd on macOS; write `Control+D` for the real Control key.
