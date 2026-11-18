# Quit with busy tabs asks (#42, criterion 2)

Quitting Slotbar with any busy tab asks the same confirmation as turning off.

Status: pending

## Sub-features

- `42-2-ask` Quit shows the confirmation with busy titles.
- `42-2-cancel` cancel: app keeps running, shells alive.
- `42-2-confirm` confirm: app exits, shells gone.

## How to get to it (user POV)

- Status item right-click > Quit, or `Cmd+Q` while the Panel is key.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, type `sleep 604` + Return.

- **Quit.** `oc hotkey --key CmdOrCtrl+Q --allow-system-shortcut` (only with the user's approval: orca blocks Cmd+Q by default). The same alert as 42-1 ("Terminate running processes?", `Terminate` / `Cancel`) appears; `V shot 42-2-ask`.
- **Cancel.** Click `Cancel`: `V doctor` process alive; `pgrep -f "sleep 604"` found.
- **Confirm.** Quit again, click `Terminate`: process gone, `sleep 604` gone. `V stop` to clean up.

## Gotchas

- `V stop` and `V relaunch` use SIGTERM, which bypasses `applicationShouldTerminate`: they never prove this criterion.
- The hook is `applicationShouldTerminate`, so Cmd+Q, the app menu and the status menu "Quit Slotbar" all ask.
- The status menu is in the system menu bar, out of reach of `orca computer`.
