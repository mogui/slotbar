# Session model "Terminal turned off" event (#42, criterion 4)

The session model handles the "Terminal turned off" event (busy tabs: ask; none: terminate all), with tests.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-125311/evidence

## Sub-features

- `42-4-busy` event with busy tabs yields one confirmation effect listing their titles.
- `42-4-idle` event with idle tabs yields terminate-all.

## How to get to it (user POV)

- Not user-visible.

## Driving it with slotbar-verify and orca computer

Preconditions: worktree at the ticket's commit.

- **Run.** `swift test --filter TerminalSessionTests`; test names include `turnedOff...` and `turnOffConfirmed...` (4 cases). The effect carries busy tab ids (`askTurnOffConfirmation([Int])`); the controller maps them to titles. Exit 0.

## Gotchas

- None.
