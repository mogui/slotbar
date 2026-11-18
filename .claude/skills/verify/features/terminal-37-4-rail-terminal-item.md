# Rail Terminal item (#37, criterion 4)

While the Terminal is on, the Rail shows the Terminal item after all Slot items and before the gear: SF Symbol `terminal`, no Profile color bar, active highlight, tooltip "Terminal", no right-click menu; absent while off; not in the Slot list.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence; right-click in /private/tmp/slotbar-verify/20261118-143906/evidence; tooltip user-reported (observed by the user, no recorded artifact)

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

- **Order and look.** `V shot 37-4-rail` and `oc get-app-state`: Rail buttons in order `button Globe`, `button Globe`, `button` (Terminal), `button` (gear); in the shot the Terminal glyph sits third and has no blue bar, the Slot globes do.
- **Highlight.** Click `Terminal`. `V shot 37-4-active`: the Terminal button has the accent background, the Slot button does not.
- **Tooltip.** User step: the user hovers the Terminal icon and reads `Terminal  ⌃⌥T`. The `orca computer` tree carries no help text; RailItemsTests `terminalTooltip*` cover the string.
- **No menu.** Right-click by window-local coordinates of the Terminal icon with `--restore-window` (user consent; element-index right-clicks are refused as `background_unavailable`): `V doctor` shows no new window. Control: the same right-click on a Slot globe opens its menu (a layer-101 window).
- **Absent.** `V stop`, `V launch` (off), `V show`: no `Terminal` button; Settings > Slots lists Example and Example Org only.
- **Tests.** `swift test --filter RailItemsTests`.

## Gotchas

- Background right-clicks are refused by `orca computer` on macOS before anything is sent; the "no menu" proof needs `--restore-window`, which takes the user's screen: ask first.
- Tooltips are not drawn in screenshots without hovering and are not in the `orca computer` tree; reading them is a user step.
