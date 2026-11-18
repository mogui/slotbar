# Shell path and starting directory fields (#44, criterion 1)

The Terminal Settings section has a shell path field (placeholder: current `$SHELL`) and a starting directory field (placeholder `~`), disabled while off, written immediately.

Status: pending

## Sub-features

- `44-1-placeholders` empty fields show `$SHELL` (e.g. `/bin/zsh`) and `~`.
- `44-1-disabled` disabled while off.
- `44-1-write` typed values land in `shellPath` / `startDirectory`; clearing a field writes `null`.

## How to get to it (user POV)

- Settings > Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch`, `V show`, click `Settings`.

- **Disabled.** `oc get-app-state --query Terminal`: both text fields disabled; placeholders visible in the tree or shot.
- **Write.** Toggle on; `oc set-value` shell field `/bin/bash`, directory field `~/work`. `V settings`: `"shellPath" : "/bin/bash"`, `"startDirectory" : "~/work"`.
- **Clear.** Set both to empty: both `null`.

## Gotchas

- `set-value` may not fire SwiftUI's commit; if `V settings` lags, type into the field (`oc type-text --element-index`) and press Return.
