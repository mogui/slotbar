# Panel shown on a Slot or Settings: the Terminal hotkey switches to the Terminal and makes the Panel key (#39, criterion 3)

Panel shown on a Slot or Settings: the Terminal hotkey switches to the Terminal and makes the Panel key. One of the four Terminal hotkey outcomes (spec "Panel, Rail and show/hide").

Status: pending

## Sub-features

- `39-3-outcome` the Panel state after the press matches the criterion.
- `39-3-focus` when the Terminal ends visible, keys reach the active tab.

## How to get to it (user POV)

- Press `Ctrl+Option+T` from any app.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`; Panel shown on Slot 1, then a second round on Settings.

- **Press.** User presses `Ctrl+Option+T` while Slot 1 is shown. `V shot 39-3-from-slot`: Terminal visible; `touch ~/hk3a` lands. Click `Settings`, press again: Terminal visible; `touch ~/hk3b` lands.
- **Proof.** `V doctor` window list before and after, shots, the touched file.

## Gotchas

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
