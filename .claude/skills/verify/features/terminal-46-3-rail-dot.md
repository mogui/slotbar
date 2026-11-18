# Dot on the Rail Terminal icon (#46, criterion 3)

The Rail Terminal icon shows a dot while any tab is flagged (RailItemsTests).

Status: pending

## Sub-features

- `46-3-dot` a bell while a Slot is shown puts a dot on the Rail Terminal icon.
- `46-3-clear` opening the Terminal on the flagged tab clears it.
- `46-3-tests` RailItemsTests cover the Terminal item's dot.

## How to get to it (user POV)

- Look at the Rail while on a Slot.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Ring while away.** Type `sleep 3; printf '\a'` + Return, `Cmd+1` at once. After 4 s `V shot 46-3-dot`: accent dot at the top-right of the Terminal Rail icon; its AX label is `Terminal, bell` in `oc get-app-state`.
- **Hidden Panel.** Repeat with `Cmd+1` then `Cmd+W` (hides from Slot 1), then `V show`: Slot 1 shown, dot on the Rail icon.
- **Clear.** Click `Terminal`: dot gone.
- **Unit.** `swift test --filter RailItemsTests`.

## Gotchas

- The Rail item AX label is `Terminal, bell` only while flagged; otherwise the button has no explicit label.
- `Cmd+W` on the Terminal closes the tab; hide from a Slot. A Panel hidden on the Terminal reopens on it and clears the flag at once.
