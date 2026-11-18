# Terminal hotkey registration (#39, criterion 1)

The KeyboardShortcuts name `toggleTerminal` defaults to `Ctrl+Option+T` and is registered only while the Terminal is enabled.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence; default driven, on/off user-reported (observed by the user, no recorded artifact)

## Sub-features

- `39-1-default` default `Ctrl+Option+T` (Settings recorder shows it).
- `39-1-on` enabled: pressing it acts.
- `39-1-off` disabled: pressing it does nothing in Slotbar and reaches the frontmost app.

## How to get to it (user POV)

- Turn the Terminal on, press `Ctrl+Option+T` anywhere.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch` (off), `V show`, `oc hotkey --key CmdOrCtrl+W` to hide.

- **Off.** User presses `Ctrl+Option+T` in another app. `V doctor` shows no Panel window.
- **On.** `V show`, Settings > Enable Terminal on, hide the Panel. User presses `Ctrl+Option+T`. `V doctor` shows the Panel window; `V shot 39-1-on` shows the Terminal.
- **Default.** `defaults delete io.github.mogui.slotbar.verify KeyboardShortcuts_toggleTerminal`, `V relaunch`: the app writes the default back (`carbonKeyCode` 17 = T, `carbonModifiers` 6144 = Control+Option) and the recorder in Settings > Terminal shows ⌃⌥T.

## Gotchas

- Registration follows `settings.terminal.enabled` on every settings apply (`Hotkey.setTerminalEnabled`, KeyboardShortcuts enable/disable). Turning the Terminal off unregisters the Carbon hotkey, so the press reaches the frontmost app (e.g. type in TextEdit: Ctrl+Option+T reaches it).

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
