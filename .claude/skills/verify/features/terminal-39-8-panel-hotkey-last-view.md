# Panel hotkey reopens the last active view (#39, criterion 8)

The Panel hotkey (and `V show`) reopens the last active view; if that is the Terminal and the Terminal has been turned off, Slot 1.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence; V show and fallback driven, Panel hotkey user-reported (observed by the user, no recorded artifact)

## Sub-features

- `39-8-terminal` last view Terminal, still on: show reopens on the Terminal.
- `39-8-fallback` last view Terminal, turned off: show opens Slot 1.

## How to get to it (user POV)

- Press the Panel hotkey or click the status item.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Last view Terminal.** Click `Terminal`, the user presses `Ctrl+Option+T` (Terminal shown and key: hides the Panel; `Cmd+W` would close the tab), `V show` (same path as the status item click: `show()` on the last view). `V shot 39-8-terminal`: Terminal.
- **Panel hotkey.** Repeat with the user pressing the Panel hotkey instead of `V show`.
- **Fallback.** Click `Terminal`, click `Settings`, toggle off, hide, `V show`: Slot 1.

## Gotchas

- Implemented in #37 (`viewToShow`); #39 adds no code for it. Covered by SlotSelectionTests `showRestoresTheTerminalWhileItIsEnabled` and `terminalTurnedOffFallsBackToSlot1`.

- Global hotkeys are Carbon hotkeys: they fire only on real keyboard events at the system level. `oc hotkey` posts to the app and does not trigger them. The live pass needs the user to press the hotkey (or an approved `--restore-window` run that proves otherwise); report "not driven: global hotkey" if neither is available.
- The user's own Slotbar may hold the same combinations; the verify copy uses its own UserDefaults (bundle id `io.github.mogui.slotbar.verify`), so its Terminal hotkey defaults to `Ctrl+Option+T` independently. If registration fails, `V logs` shows it; ask the user to quit their Slotbar for the run.
