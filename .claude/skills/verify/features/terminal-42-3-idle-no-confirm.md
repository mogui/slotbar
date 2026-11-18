# Idle tabs turn off and quit without asking (#42, criterion 3)

Turning off or quitting with every tab idle at the prompt needs no confirmation.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence; turn-off in /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `42-3-off` idle tabs: the toggle turns off at once.
- `42-3-quit` idle tabs: Quit exits at once.

## How to get to it (user POV)

- Settings toggle off; Quit.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T` (two idle tabs).

- **Off.** Click `Settings`, toggle off. No dialog (`V doctor` shows only the Panel window); `V shells` empty.
- **Quit.** `V relaunch`, two idle tabs, `osascript -e 'tell application id "io.github.mogui.slotbar.verify" to quit'`. Process exits within 2 s; the app log has no `begin modal`.

## Gotchas

- A prompt with a background job (`sleep 9 &`) is still idle by the spec's rule (foreground group = shell); add it as an extra case.
