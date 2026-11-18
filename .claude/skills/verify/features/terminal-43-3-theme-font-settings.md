# Theme picker and font size stepper in Settings (#43, criterion 3)

The Terminal Settings section has a theme picker and a font size stepper (9-36), disabled while off, written immediately; a Settings change applies live to all tabs.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `43-3-disabled` both controls disabled while off.
- `43-3-write` changes are in `settings.json` at once.
- `43-3-range` the stepper stops at 9 and 36.
- `43-3-live-all` two tabs both change theme/size without new tabs.

## How to get to it (user POV)

- Settings > Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch`, `V show`, click `Settings`.

- **Disabled.** `oc get-app-state --query Terminal`: picker and stepper disabled.
- **Enable and change.** Toggle on; set theme `dracula` (popup: see terminal-43-1); increment the stepper 3 times (`oc perform-secondary-action --action increment`). `V settings`: `theme dracula`, `fontSize 16`.
- **Range.** Decrement past 9, increment past 36: values clamp.
- **Live, all tabs.** Click `Terminal`, `Cmd+T`, type `stty size > ~/s1` in each tab; change the size in Settings; back in each tab `stty size > ~/s2`: both tabs' sizes changed (fewer rows/cols with a bigger font).

## Gotchas

- Stepper label reads `Font size: N pt`; it sits after the Theme picker, before Shell.
- A Settings size change also resets any live `Cmd+=`/`Cmd+-` size.

- The stepper may be one element with increment/decrement actions; use `oc perform-secondary-action` with the listed action names.
