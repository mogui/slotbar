# Quit with busy tabs asks (#42, criterion 2)

Quitting Slotbar with any busy tab asks the same confirmation as turning off.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence

## Sub-features

- `42-2-ask` Quit shows the confirmation with busy titles.
- `42-2-cancel` cancel: app keeps running, shells alive.
- `42-2-confirm` confirm: app exits, shells gone.

## How to get to it (user POV)

- Status item right-click > Quit, or `Cmd+Q` while the Panel is key.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, type `sleep 604` + Return.

- **Quit.** In the background, `osascript -e 'tell application id "io.github.mogui.slotbar.verify" to quit'` (the Quit Apple Event reaches `applicationShouldTerminate` like Cmd+Q; `oc hotkey --key CmdOrCtrl+Q` is blocked by orca without the user's approval). The same alert as 42-1 ("Terminate running processes?", `Terminate` / `Cancel`) appears as a layer-8 window; read it with `oc get-app-state --window-id <id>`, `screencapture -l<id>` into evidence.
- **Cancel.** Click `Cancel`: process alive; `pgrep -f "sleep 604"` found; osascript reports `User cancelled. (-128)`.
- **Confirm.** Quit again, click `Terminate`: process gone, `sleep 604` gone. `V stop` to clean up.

## Gotchas

- `V stop` and `V relaunch` use SIGTERM, which bypasses `applicationShouldTerminate`: they never prove this criterion.
- The hook is `applicationShouldTerminate`, so Cmd+Q, the app menu and the status menu "Quit Slotbar" all ask.
- The status menu is in the system menu bar, out of reach of `orca computer`.
