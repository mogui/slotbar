# Shell path and starting directory fields (#44, criterion 1)

The Terminal Settings section has a shell path field (placeholder: current `$SHELL`) and a starting directory field (placeholder `~`), disabled while off, written immediately.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `44-1-placeholders` empty fields show `$SHELL` (e.g. `/bin/zsh`) and `~`.
- `44-1-disabled` disabled while off.
- `44-1-write` typed values land in `shellPath` / `startDirectory`; clearing a field writes `null`.

## How to get to it (user POV)

- Settings > Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch`, `V show`, click `Settings`.

- **Disabled.** `oc get-app-state --query Terminal`: text fields `Shell` and `Starting directory` disabled; placeholders (`$SHELL` of the app process, `~`) visible in the tree or shot.
- **Write.** Toggle on; for each field: click it with `--restore-window`, `oc hotkey --key CmdOrCtrl+A`, `oc type-text --text <value>`, `oc press-key --key Return`. Shell `/bin/bash`, directory `~/work`. `V settings`: `"shellPath" : "/bin/bash"`, `"startDirectory" : "~/work"`.
- **Clear.** Same path with `Delete` instead of text: both `null`.

## Gotchas

- The fields commit on Return or when they lose focus, not per keystroke. `set-value` and `type-text --element-index` change the visible text without committing; a later focus change can then commit unexpected text, so always go through the focused-field path above.
- An empty field writes `null`, other text is stored verbatim (no trimming).
- The shell placeholder is the app process's `$SHELL`, falling back to `/bin/zsh` when unset.
