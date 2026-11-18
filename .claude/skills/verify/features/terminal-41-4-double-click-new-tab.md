# Double-click empty tab bar opens a tab (#41, criterion 4)

Double-clicking the empty part of the tab bar opens a new tab.

Status: pending

## Sub-features

- `41-4-empty` double-click right of the last tab opens one.
- `41-4-on-tab` double-click on a tab does not open one.

## How to get to it (user POV)

- Double-click the tab bar background.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T` (two tabs).

- **Empty area.** From `V shot`, pick a point in the strip right of the last tab; `oc click --x <x> --y <y> --click-count 2` (check `oc click --help` for the multi-click flag). `V shells`: 3.
- **On a tab.** Double-click a tab: `V shells` unchanged.

## Gotchas

- Coordinates are window-local; take them from the latest shot and its `scale`.
- If background multi-clicks are refused, ask the user before `--restore-window`.
