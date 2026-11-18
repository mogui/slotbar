# Panel shown on the Terminal and key: the hotkey hides it (#39, criterion 5)

Panel shown on the Terminal and key: the hotkey hides it. One of the four Terminal hotkey outcomes (spec "Panel, Rail and show/hide").

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence - user-reported (observed by the user, no recorded artifact)

## Sub-features

- `39-5-outcome` the Panel state after the press matches the criterion.
- `39-5-focus` when the Terminal ends visible, keys reach the active tab.

## How to get to it (user POV)

- Press `Ctrl+Option+T` from any app.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`; Panel shown on the Terminal and key (just clicked into it).

- **Press.** User presses `Ctrl+Option+T`. `V doctor` shows no Panel window; `V shells` pid unchanged (shell kept running).
- **Proof.** `V doctor` window list before and after, shots, the touched file.

## Gotchas

- Hiding reactivates the app that was frontmost at show; the shell keeps running (`V shells` same pid).

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
