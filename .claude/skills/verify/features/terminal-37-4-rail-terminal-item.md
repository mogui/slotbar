# Rail Terminal item (#37, criterion 4)

While the Terminal is on, the Rail shows the Terminal item after all Slot items and before the gear: SF Symbol `terminal`, no Profile color bar, active highlight, tooltip "Terminal", no right-click menu; absent while off; not in the Slot list.

Status: pending

## Sub-features

- `37-4-order` Slot 1, Slot 2, Terminal, gear (top to bottom on the right edge).
- `37-4-look` terminal glyph, no colored bar beside it.
- `37-4-highlight` the Terminal button is highlighted while the Terminal is the active view.
- `37-4-tooltip` help text exactly "Terminal  ⌃⌥T" (two spaces; "Terminal" alone when the hotkey is cleared).
- `37-4-no-menu` right-click shows no menu.
- `37-4-absent` no Terminal button while off; Settings > Slots lists only the two Slots.
- `37-4-tests` RailItemsTests.

## How to get to it (user POV)

- Open the Panel; look at the Rail.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Order and look.** `V shot 37-4-rail` and `oc get-app-state`: Rail buttons in order `Example  ⌘1`, `Example Org  ⌘2`, `Terminal  ⌃⌥T`, `Settings`; in the shot the Terminal glyph has no blue bar, the Slot globes do.
- **Highlight.** Click `Terminal`. `V shot 37-4-active`: the Terminal button has the accent background, the Slot button does not.
- **Tooltip.** The element's help text in `oc get-app-state` is exactly `Terminal  ⌃⌥T`.
- **No menu.** `oc click --element-index <Terminal> --mouse-button right`. Refused as `background` menu-opening or opens nothing; with `--restore-window` (user consent) no menu window appears in `V doctor`.
- **Absent.** `V stop`, `V launch` (off), `V show`: no `Terminal` button; Settings > Slots lists Example and Example Org only.
- **Tests.** `swift test --filter RailItemsTests`.

## Gotchas

- Background right-clicks are refused by `orca computer` on macOS before anything is sent; the "no menu" proof needs `--restore-window`, which takes the user's screen: ask first.
- Tooltips are not drawn in screenshots without hovering; rely on the accessibility help text.
