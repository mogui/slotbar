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
- **Bad directory.** Settings: shell empty, directory `/nonexistent/dir`; Return in the failed tab: `Starting directory /nonexistent/dir does not exist`.
- **Logs.** `V logs`: `Shell start failed: ...` at error level in category `Terminal`.

## Gotchas

- Missing/non-executable/directory shell and missing directory are caught before spawning (`shellStartError`): no child process at all, text `Cannot start shell <path>: no such file` (or `is a directory`, `not executable`).
- A shell that exits within 2 s of its spawn (any exit code) is a start failure: `Shell <path> exited with code N at start`. To test it, use an executable that exits at once, e.g. shell `/usr/bin/false`. A shell that exits after 2 s respawns as before.
- While failed, every key except Return is dropped by the tab; Panel shortcuts (Cmd+W, Cmd+1..9) still work.
- Turning the Terminal off and on creates a new tab, which also re-checks the settings.
