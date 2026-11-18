# Fresh tab after relaunch (#37, criterion 11)

After quitting and relaunching Slotbar with the Terminal on, the Terminal starts with one fresh tab: new shell, no previous scrollback.

Status: pending

## Sub-features

- `37-11-one-tab` exactly one shell after relaunch, with a new pid.
- `37-11-no-scrollback` the previous session's output is not shown.

## How to get to it (user POV)

- Quit Slotbar (status menu > Quit) and open it again.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Before.** Type `echo BEFORE-RELAUNCH` + Return. `V shells` into `<run>/evidence/37-11-before.txt`.
- **Relaunch.** `V relaunch`, `V show`, click `Terminal`.
- **After.** `V shells` into `37-11-after.txt`: one shell, different pid. `V shot 37-11-after`: no `BEFORE-RELAUNCH` line.

## Gotchas

- `V relaunch` sends SIGTERM, not a user Quit; for this criterion that is equivalent (nothing persists the tab). For Quit-specific behaviour see terminal-42-2.
