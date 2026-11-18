# Active tab is first responder (#37, criterion 6)

Whenever the Terminal becomes visible (Rail click, Panel shown on the Terminal) the active tab is first responder: typing goes to the shell without a click.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `37-6-rail` after a Rail click, keys reach the shell.
- `37-6-reshow` after hiding and re-showing the Panel on the Terminal, keys reach the shell.
- `37-6-from-settings` after Settings then Terminal, keys reach the shell.

## How to get to it (user POV)

- Click the Terminal icon and start typing.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Rail.** Click `Terminal`; without clicking the terminal area, `oc type-text --text 'touch ~/fr-rail'` + Return. `<run>/home/fr-rail` exists.
- **Re-show.** Hide the Panel on the Terminal: `Cmd+W` on the last tab (hides and respawns its shell), or the user presses `Ctrl+Option+T`. `V show` (reopens on the Terminal), type `touch ~/fr-reshow` + Return. File exists.
- **From Settings.** Click `Settings`, click `Terminal`, type `touch ~/fr-settings` + Return. File exists.
- **Proof.** `ls <run>/home` and a shot after each step.

## Gotchas

- `oc type-text` reports `unverified (text mismatch)` on the terminal view; the touched files are the proof.
- `orca computer` sends keys to the app's key window; if the Panel is not key, keys go nowhere. A failure here may be the harness, so check `oc get-app-state` focused element before concluding.
