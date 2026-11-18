# Terminal-active Panel shortcut mappings (#40, criterion 7)

Panel shortcut matching takes whether the Terminal is active and defines every Terminal-active mapping: `Cmd+T`, `Cmd+W`, `Cmd+Shift+[`/`]`, `Cmd+K`, `Cmd+=`/`Cmd+-`/`Cmd+0`, `Cmd+R` consumed with no action, `Cmd+1..9` and `Cmd+Shift+H`/`O` unchanged (H/O no-op on the Terminal); clear and font size are no-ops until their tickets.

Status: pending

## Sub-features

- `40-7-tabs` T, W, Shift+[ and ] act on tabs.
- `40-7-r` `Cmd+R` does nothing (no Slot reload, nothing typed in the shell).
- `40-7-digits` `Cmd+2` shows Slot 2.
- `40-7-h-o` `Cmd+Shift+H`/`O` do nothing.
- `40-7-k-font` `Cmd+K`, `Cmd+=`, `Cmd+-`, `Cmd+0` are consumed (no character reaches the shell) and act once #43/#45 land.

## How to get to it (user POV)

- Keyboard with the Terminal active.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Cmd+R.** Type `cat -v` + Return, `oc hotkey --key CmdOrCtrl+R`: nothing appears in `cat`; `V logs` has no reload; `Control+C` to end.
- **Cmd+K, Cmd+=, Cmd+-, Cmd+0.** Same `cat -v` probe: nothing printed for each.
- **H/O.** `Cmd+Shift+H`, `Cmd+Shift+O`: no browser opens, Terminal stays.
- **Digits.** `Cmd+2`: Slot 2 shown.
- **Tabs.** see terminal-40-2 and 40-3.
- **Unit.** `swift test --filter PanelShortcutTests`.

## Gotchas

- `Cmd+=` and `Cmd++` (with or without Shift) both map to font larger; clear and font keys are consumed with no action until #45 / #43.
- `Cmd+Shift+O` would open the user's browser if mis-mapped; warn the user first.
