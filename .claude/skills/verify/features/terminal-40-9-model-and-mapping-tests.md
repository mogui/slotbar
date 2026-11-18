# Session model and mapping tests (#40, criterion 9)

Session model rules are unit-tested in SlotLifecycleTests style; every Terminal-active mapping is tested in PanelShortcutTests.

Status: pending

## Sub-features

- `40-9-model` one test per rule: start with one tab, open, select, next/previous, close idle, close busy asks, confirm, last-tab close hides, last-tab exit respawns, shown/hidden.
- `40-9-mappings` one case per mapping in terminal-40-7.

## How to get to it (user POV)

- Not user-visible.

## Driving it with slotbar-verify and orca computer

Preconditions: worktree at the ticket's commit.

- **Run.** `swift test --filter "PanelShortcutTests|<SessionModel suite>"`. Exit 0.
- **Coverage read.** List test names; tick each rule and mapping above.

## Gotchas

- None beyond locating the suite name.
