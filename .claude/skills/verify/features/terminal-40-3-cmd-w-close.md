# Cmd+W closes the current tab (#40, criterion 3)

`Cmd+W` closes the current tab; on the last tab it replaces it with a fresh shell and hides the Panel.

Status: pending

## Sub-features

- `40-3-close` with two tabs, `Cmd+W` leaves one; its shell is terminated.
- `40-3-last` with one tab, `Cmd+W` hides the Panel and the next show has a fresh shell (new pid, empty screen).

## How to get to it (user POV)

- `Cmd+W` in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Two tabs.** `oc hotkey --key CmdOrCtrl+T`, `V shells` (2), `oc hotkey --key CmdOrCtrl+W`, `V shells` (1, the closed pid gone), Panel still shown.
- **Last tab.** Type `echo OLD` + Return, note pid, `oc hotkey --key CmdOrCtrl+W`. `V doctor`: no Panel window; `V shells`: one shell, new pid. `V show`: `V shot 40-3-fresh` has no `OLD`.

## Gotchas

- With a busy current tab `Cmd+W` asks for confirmation (terminal-40-5); keep tabs idle here.
