# Double-click empty tab bar opens a tab (#41, criterion 4)

Double-clicking the empty part of the tab bar opens a new tab.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `41-4-empty` double-click right of the last tab opens one.
- `41-4-on-tab` double-click on a tab does not open one.

## How to get to it (user POV)

- Double-click the tab bar background.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T` (two tabs).

- **Empty area.** Tabs are left-aligned, each `min(200 pt, bar width / tab count)` wide, so with two tabs and a Panel wider than 400 pt the empty part starts at x = 400 pt in the 28 pt strip at the top. From `V shot`, pick a point there; `oc click --x <x> --y <y> --click-count 2` (check `oc click --help` for the multi-click flag). `V shells`: 3.
- **On a tab.** Double-click a tab: `V shells` unchanged.

## Gotchas

- Coordinates are window-local; take them from the latest shot and its `scale`.
- With tabs filling the whole width (narrow Panel or many tabs) there is no empty part; widen the Panel or use fewer tabs.
- If background multi-clicks are refused, ask the user before `--restore-window`.
