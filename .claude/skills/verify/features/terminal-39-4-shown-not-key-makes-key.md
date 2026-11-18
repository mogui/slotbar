# Panel shown on the Terminal but not key: the hotkey makes it key without hiding (#39, criterion 4)

Panel shown on the Terminal but not key: the hotkey makes it key without hiding. One of the four Terminal hotkey outcomes (spec "Panel, Rail and show/hide").

Status: pending

## Sub-features

- `39-4-outcome` the Panel state after the press matches the criterion.
- `39-4-focus` when the Terminal ends visible, keys reach the active tab.

## How to get to it (user POV)

- Press `Ctrl+Option+T` from any app.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`; Panel shown on the Terminal; another app made key by the user clicking it (hide on focus loss is off in the seed, so the Panel stays).

- **Press.** User presses `Ctrl+Option+T`. `V doctor` still shows the Panel; type via the user or `oc type-text` `touch ~/hk4` + Return: file exists (key).
- **Proof.** `V doctor` window list before and after, shots, the touched file.

## Gotchas

- "Key" counts the Panel or a Child window. The terminal view keeps first responder from when it was activated, so after makeKey typing lands in the shell without a click.

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
