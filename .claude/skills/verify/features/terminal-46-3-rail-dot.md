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

- **Ring while away.** Type `sleep 3; printf '\a'` + Return, `Cmd+1` at once. After 4 s `V shot 46-3-dot`: dot on the Terminal Rail icon.
- **Hidden Panel.** Repeat with `Cmd+W` instead of `Cmd+1`, then `V show`: dot on the Rail icon (Panel shows the last view, the Terminal, which then clears it: shoot immediately or show on a Slot).
- **Clear.** Click `Terminal`: dot gone.
- **Unit.** `swift test --filter RailItemsTests`.

## Gotchas

- With the Panel hidden, `V show` reopens on the Terminal and clears the flag at once; use the Slot variant for the screenshot.
