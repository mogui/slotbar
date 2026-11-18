# New tab and tab switching by keyboard (#40, criterion 2)

`Cmd+T` opens a tab; `Cmd+Shift+[` / `Cmd+Shift+]` select the previous / next tab.

Status: pending

## Sub-features

- `40-2-new` `Cmd+T` spawns a shell and makes the new tab active.
- `40-2-prev-next` `Cmd+Shift+[` and `]` move the active tab, wrapping or stopping at the ends as implemented.

## How to get to it (user POV)

- Keyboard in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **New.** `oc hotkey --key CmdOrCtrl+T`. `V shells`: 2 shells. Type `touch ~/tab2` + Return: lands (new tab active and focused).
- **Previous.** `oc hotkey --key CmdOrCtrl+Shift+[`, type `tty > ~/tty-prev` + Return. **Next.** `oc hotkey --key CmdOrCtrl+Shift+]`, type `tty > ~/tty-next` + Return. The two ttys differ and match the two shells in `V shells`.
- **Proof.** shots (tab bar from #41 if merged), `V shells`, the tty files.

## Gotchas

- On an Italian layout `[`/`]` are Option chords; macOS maps `Cmd+Shift+[` by key equivalent characters. If `oc hotkey` cannot express the bracket, use `--key "CmdOrCtrl+Shift+BracketLeft"` per `oc hotkey --help`.
- `oc type-text` on the terminal view reports `unverified (text mismatch)`; prove with shots, `V shells` and files under `<run>/home`.
