# Terminal hotkey recorder in Settings (#39, criterion 6)

The Terminal Settings section has a hotkey recorder for `toggleTerminal`, disabled while the Terminal is off.

Status: pending

## Sub-features

- `39-6-present` recorder in the Terminal section showing ⌃⌥T.
- `39-6-disabled` disabled while "Enable Terminal" is off.
- `39-6-change` recording a new combination stores it and the new combination works.

## How to get to it (user POV)

- Settings > Terminal > hotkey recorder.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch` (off), `V show`, click `Settings`, scroll to Terminal.

- Label: `Terminal hotkey`, right after "Enable Terminal". No "could not be registered" warning exists for this hotkey (only the Panel hotkey has one).
- **Disabled.** `oc get-app-state --query Terminal`: the recorder element is disabled.
- **Enabled.** Toggle "Enable Terminal" on: recorder enabled, value ⌃⌥T.
- **Change.** Click the recorder, user presses `Ctrl+Option+Y` (a recorder needs real keys). `defaults read io.github.mogui.slotbar.verify KeyboardShortcuts_toggleTerminal` shows the new combination. Hide the Panel; user presses `Ctrl+Option+Y`: Panel shows on the Terminal.

## Gotchas

- Recording writes the verify copy's UserDefaults only (`io.github.mogui.slotbar.verify`); delete the key afterwards with `defaults delete io.github.mogui.slotbar.verify KeyboardShortcuts_toggleTerminal` (not removed by `V stop`).
- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
