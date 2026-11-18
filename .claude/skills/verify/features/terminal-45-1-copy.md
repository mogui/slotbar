# Cmd+C copies, selecting does not (#45, criterion 1)

`Cmd+C` copies the selection; selecting text never writes the clipboard.

Status: pending

## Sub-features

- `45-1-select-only` dragging a selection leaves the clipboard unchanged.
- `45-1-copy` `Cmd+C` puts the selected text on the clipboard.

## How to get to it (user POV)

- Drag over output, press `Cmd+C`.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, type `echo COPY-ME-45` + Return. Save the user's clipboard: `pbpaste > <run>/clipboard.bak`, then `printf SENTINEL | pbcopy`.

- **Select.** `oc drag` across `COPY-ME-45` (coordinates from the shot). `pbpaste` is still `SENTINEL`.
- **Copy.** `oc hotkey --key CmdOrCtrl+C`. `pbpaste` contains `COPY-ME-45`.
- **Restore.** `pbcopy < <run>/clipboard.bak`.

## Gotchas

- The clipboard is the user's: always back it up and restore it.
- Background drags may not create a selection in a custom NSView; if not, ask before `--restore-window`.
- Built: SwiftTerm's `copy:` via Slotbar's hidden Edit menu; with no selection `Cmd+C` does nothing (menu item disabled). Programs can still write the clipboard with OSC 52; that is not a selection.
