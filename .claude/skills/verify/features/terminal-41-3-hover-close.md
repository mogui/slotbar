# Hover close button on a tab (#41, criterion 3)

Hovering a tab shows a close button; closing goes through "close requested", so a busy tab asks for confirmation.

Status: pending

## Sub-features

- `41-3-hover` the close button appears on hover only.
- `41-3-close-idle` clicking it on an idle tab closes it.
- `41-3-close-busy` on a busy tab it asks first (same dialog as `Cmd+W`).

## How to get to it (user POV)

- Mouse over a tab, click its x.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T` twice (three tabs).

- **Hover.** `V shot 41-3-no-hover`; the close button is absent. Hover needs the real pointer: with the user's consent `oc click`-free hover is not available, so check the tree: the close button element exists and is hidden/unhittable until hover, or ask the user to hover and take `V shot 41-3-hover`.
- **Close idle.** Click the close button element of tab 3 (`oc get-app-state --query close`). `V shells`: 2.
- **Close busy.** In tab 2 type `sleep 601` + Return, click its close button: confirmation appears; cancel keeps `sleep 601`.

## Gotchas

- `orca computer` has no hover action; hover visuals need the user or `--restore-window` with a pointer move. Report the hover sub-feature as "not driven" if neither is available.
- Unique `sleep` durations per recipe avoid matching other processes.
