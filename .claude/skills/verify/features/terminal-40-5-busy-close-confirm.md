# Busy tab asks before closing (#40, criterion 5)

Close requested on a busy tab (the pty's foreground process group differs from the shell pid) asks for confirmation; otherwise the tab closes at once.

Status: pending

## Sub-features

- `40-5-busy` `sleep 600` running: `Cmd+W` shows a confirmation.
- `40-5-cancel` cancel keeps the tab and `sleep` running.
- `40-5-confirm` confirm closes the tab and kills `sleep`.
- `40-5-idle` idle at the prompt: closes without asking.

## How to get to it (user POV)

- `Cmd+W` (or the tab close button from #41) while a program runs.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Busy.** `Cmd+T`, type `sleep 600` + Return, `oc hotkey --key CmdOrCtrl+W`. `oc get-app-state` shows a sheet on the Panel: "Close this tab?", buttons `Close` (default) and `Cancel`; `V shot 40-5-confirm`.
- **Cancel.** Click the cancel button. `pgrep -f "sleep 600"` still finds it; 2 shells.
- **Confirm.** `Cmd+W` again, click the confirm button. `pgrep -f "sleep 600"` empty; 1 shell.
- **Idle.** `Cmd+T`, `Cmd+W`: no dialog, 1 shell.

## Gotchas

- `sleep 600` with a unique duration avoids matching other `sleep` processes on the Mac; never `pkill sleep`.
- The alert is a sheet on the Panel window (`beginSheetModal`), not app-modal; Escape = `Cancel`, Return = `Close`.
- Busy = the pty foreground process group differs from the shell pid (`tcgetpgrp`); a job in the background (`sleep 600 &`) is not busy.
