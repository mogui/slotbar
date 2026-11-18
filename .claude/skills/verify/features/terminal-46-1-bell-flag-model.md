# Bell flag in the session model (#46, criterion 1)

A bell on a tab that is not visible (another tab active, or the Terminal not shown) sets its flag; the flag clears when the tab becomes visible. Tested in the session model.

Status: pending

## Sub-features

- `46-1-other-tab` bell in an inactive tab flags it.
- `46-1-hidden` bell while the Panel is hidden or a Slot is shown flags the active tab.
- `46-1-visible` bell in the visible tab sets no flag.
- `46-1-clear` showing the tab clears the flag.
- `46-1-tests` session model tests for each rule.

## How to get to it (user POV)

- Run a long command ending in a bell, look elsewhere.

## Driving it with slotbar-verify and orca computer

Preconditions: worktree at the ticket's commit.

- **Unit.** `swift test --filter TerminalSessionTests`: the `bell...`, `showingTheTerminalClears...`, `selectingAFlaggedTab...` cases pass.
- **Live.** Covered by terminal-46-2 and 46-3 (the flag is only visible as dots).

## Gotchas

- "Visible" = Panel shown on the Terminal and not on Settings (`PanelController.updateShown` -> `setShown`); key state is ignored, so a bell in the active tab of a shown but non-key Panel sets no flag.
- SwiftTerm still beeps (NSSound.beep) on every bell; that is expected.
