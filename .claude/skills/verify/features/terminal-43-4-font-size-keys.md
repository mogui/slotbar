# Cmd+= / Cmd+- / Cmd+0 font size (#43, criterion 4)

`Cmd+=` / `Cmd+-` / `Cmd+0` enlarge, shrink and reset to the Settings size, for all tabs, without saving.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence; not-saved in /private/tmp/slotbar-verify/20261118-143906/evidence

## Sub-features

- `43-4-larger`, `43-4-smaller`, `43-4-reset` change the size live.
- `43-4-all-tabs` every tab follows.
- `43-4-not-saved` `settings.json` `fontSize` unchanged; after relaunch the Settings size is back.

## How to get to it (user POV)

- Keyboard in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T`.

- **Larger.** `stty size > ~/a`, `oc hotkey --key CmdOrCtrl+=` twice, `stty size > ~/b`: fewer rows/cols. Switch tab, `stty size > ~/b2`: matches `b`.
- **Smaller / reset.** `CmdOrCtrl+-`, then `CmdOrCtrl+0`: `stty size` back to `a`.
- **Not saved.** After the changes `V settings` `fontSize` 13; `V relaunch`: size as `a`.

## Gotchas

- `Cmd+=` on some layouts is `Cmd+Shift+=` (`+`); the mapping should accept both, test both.
- Steps are 1 pt, clamped 9-36; new tabs open at the live size. A Settings size change replaces the live size.
