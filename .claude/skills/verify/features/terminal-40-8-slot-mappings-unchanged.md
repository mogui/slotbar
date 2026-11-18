# Slot-active shortcut matching unchanged (#40, criterion 8)

With a Slot active, the Panel shortcuts behave as before the Terminal: `Cmd+R` reload, `Cmd+W` hide Panel, `Cmd+Shift+H` Home, `Cmd+Shift+O` open in browser, `Cmd+1..9` Slots; `Cmd+T` and `Cmd+K` are not taken by the Panel.

Status: pending

## Sub-features

- `40-8-reload`, `40-8-hide`, `40-8-home`, `40-8-digits` unchanged.
- `40-8-unmapped` `Cmd+T` with a Slot active opens no Terminal tab (`V shells` count unchanged).

## How to get to it (user POV)

- Keyboard with a Slot shown.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show` (Slot 1).

- **Cmd+T on a Slot.** `V shells` count, `oc hotkey --key CmdOrCtrl+T`, count unchanged.
- **Cmd+2 / Cmd+1.** Slots switch.
- **Cmd+W.** Panel hides (`V doctor`).
- **Unit.** `swift test --filter PanelShortcutTests`: the pre-existing Slot cases pass unchanged (`git diff main -- Tests/SlotbarTests/PanelShortcutTests.swift`: the Slot case lists keep their entries; calls go through the `match(_:terminalActive: false)` helper; new unbound cases added).

## Gotchas

- `Cmd+Shift+O` on a Slot opens the user's default browser for real; skip it or ask first.
