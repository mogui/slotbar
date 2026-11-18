# Settings Enable Terminal toggle (#37, criterion 3)

Settings has a "Terminal" section next to General, Profiles and Slots with the "Enable Terminal" toggle; off by default; written immediately.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `37-3-section` the Settings Form shows sections General, Profiles, Slots, Terminal.
- `37-3-default-off` a fresh install shows the toggle off.
- `37-3-write` toggling writes `terminal.enabled` at once and the Rail updates without relaunch.

## How to get to it (user POV)

- Click the gear at the bottom of the Rail; scroll to the Terminal section.
- Status item right-click menu > Settings (not reachable by the harness).

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch` (Terminal off), `V show`.

- **Open Settings.** Click the Rail button with help `Settings`. `oc get-app-state` shows `heading Terminal`, `text Enable Terminal` and right after it an unlabelled `switch, Value: 0`.
- **Turn on.** Click the switch. `V settings` shows `"enabled" : true` immediately; the Rail gains an unnamed `button` between the `button Globe` Slot buttons and the gear; `V shells` lists one `-zsh`.
- **Turn off.** Click the switch again. `enabled` false, Rail button gone, `V shells` empty.
- **Proof.** `V shot 37-3-off`, `V shot 37-3-on`, `V settings` after each click.

## Gotchas

- Settings is one long Form: the Terminal section may be below the fold; scroll the Form (`oc scroll --direction down`) before reading or clicking.
- A fresh install (no settings file) writes the first-run preset with Gmail/Calendar/Chat Slots that load Google pages; the seeded file avoids that. For "off by default" check the seed-free preset once: remove the settings file and `V relaunch`, then `V settings`.
