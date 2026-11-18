# Panel hidden: the Terminal hotkey shows it on the Terminal (#39, criterion 2)

Panel hidden: the Terminal hotkey shows it on the Terminal. One of the four Terminal hotkey outcomes (spec "Panel, Rail and show/hide").

Status: pending

## Sub-features

- `39-2-outcome` the Panel state after the press matches the criterion.
- `39-2-focus` when the Terminal ends visible, keys reach the active tab.

## How to get to it (user POV)

- Press `Ctrl+Option+T` from any app.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`; Panel hidden (`oc hotkey --key CmdOrCtrl+W`), last view Slot 1.

- **Press.** User presses `Ctrl+Option+T`. `V doctor` shows the Panel window; `V shot 39-2`: Terminal visible, Rail highlight on Terminal; type `touch ~/hk2` + Return and `<run>/home/hk2` exists (key and focused).
- **Proof.** `V doctor` window list before and after, shots, the touched file.

## Gotchas

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
