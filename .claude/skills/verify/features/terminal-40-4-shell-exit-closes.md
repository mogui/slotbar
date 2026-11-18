# Shell exit closes its tab (#40, criterion 4)

A shell exit (`exit`, `Ctrl+D`) closes its tab; on the last tab it is replaced by a fresh shell and the Panel stays shown.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

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

- Wait more than 2 s after a spawn before `exit`/`Control+D`: an exit within 2 s is a start failure (#44 error screen, tab kept), not a shell exit.
- `oc hotkey` uses `CmdOrCtrl` for Cmd on macOS; write `Control+D` for the real Control key.
