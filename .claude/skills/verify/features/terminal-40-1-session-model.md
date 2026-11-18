# Terminal session model (#40, criterion 1)

A pure session model owns the tab list, active tab and titles; it takes events (open, select, next/previous, close requested, close confirmed, shell exited, shown/hidden) and returns effects (spawn shell, terminate shell, ask confirmation, hide Panel); it starts with one tab and never holds zero.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `40-1-pure` the model is a value type with no AppKit/SwiftTerm import.
- `40-1-events-effects` every listed event and effect exists and is tested.
- `40-1-never-zero` no event sequence leaves zero tabs.
- `40-1-live` the controller follows the model: `V shells` count equals the visible tab count.

## How to get to it (user POV)

- Indirect: every tab action.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Tests.** `swift test --filter TerminalSessionTests`. All pass.
- **Purity.** `grep -n "^import" Sources/Slotbar/Terminal/TerminalSession.swift`: no imports.
- **Live count.** `Cmd+T` twice (`oc hotkey --key CmdOrCtrl+T`): `V shells` shows 3 shells; `Cmd+W` once: 2.

## Gotchas

- Model: `TerminalSession` (`Sources/Slotbar/Terminal/TerminalSession.swift`), one entry point `handle(_ Event) -> [Effect]`; `TerminalController` performs the effects.
- Wait more than 2 s after a spawn before `exit`: an exit within 2 s is a start failure (#44 error screen, tab kept), not a shell exit.
