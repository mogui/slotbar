# Turning the Terminal off while active shows Slot 1 (#37, criterion 10)

If the Terminal is the active view when it is turned off, the Panel switches to Slot 1.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `37-10-fallback` last active view Terminal + turned off: next show is Slot 1.
- `37-10-while-settings` turning it off from Settings leaves Settings shown; leaving Settings shows Slot 1.

## How to get to it (user POV)

- Use the Terminal, open Settings, turn the Terminal off, then click away or re-show the Panel.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Make Terminal active.** Click `Terminal`.
- **Turn off.** Click `Settings`, click "Enable Terminal" (off). `V shot 37-10-settings`.
- **Hide and re-show.** `oc hotkey --key CmdOrCtrl+W`, `V show`. `V shot 37-10-after`: Slot 1 (example.com), highlight on `Example`, no Terminal button.

## Gotchas

- The settings toggle is inside the Panel, so the Terminal is never the visible view at the moment it is turned off from the UI; the fallback shows up on the next show (or leaving Settings).
