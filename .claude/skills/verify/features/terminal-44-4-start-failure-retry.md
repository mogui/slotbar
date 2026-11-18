# Shell start failure and Return to retry (#44, criterion 4)

A shell that fails to start leaves the tab showing the error and "Press Return to try again"; Return respawns with the current settings.

Status: pending

## Sub-features

- `44-4-error` a nonexistent shell path shows the error text and the retry hint.
- `44-4-retry-fail` Return with the same bad path shows the error again.
- `44-4-retry-ok` after fixing the setting, Return starts a working shell.

## How to get to it (user POV)

- Set a wrong shell path, open a tab.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Error.** Settings: shell `/nonexistent/shell`. Click `Terminal`, `Cmd+T`. `V shot 44-4-error`: error text and `Press Return to try again`; `V shells` has no new child.
- **Retry fail.** `oc press-key --key Return`: same message.
- **Fix and retry.** Settings: clear the shell field. Click `Terminal`, select the failed tab, Return: a prompt; `V shells` shows a new `-zsh`.
- **Logs.** `V logs`: a start-failure line in category `Terminal`.

## Gotchas

- SwiftTerm may report the failure through `processTerminated` with an exit code instead of `processFailedToStart`; the visible text is the criterion either way.
