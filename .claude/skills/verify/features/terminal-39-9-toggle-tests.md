# Tests for the hotkey outcomes (#39, criterion 9)

Unit tests cover the four Terminal hotkey outcomes and the last-view fallback (PanelToggleTests, SlotSelectionTests style).

Status: pending

## Sub-features

- `39-9-outcomes` hidden, on Slot/Settings, on Terminal not key, on Terminal key.
- `39-9-fallback` last view Terminal + off gives Slot 1.

## How to get to it (user POV)

- Not user-visible.

## Driving it with slotbar-verify and orca computer

Preconditions: worktree at the ticket's commit.

- **Run.** `swift test --filter "PanelToggleTests|SlotSelectionTests"` (plus the new suite name if the ticket adds one). Exit 0; the output lists one test per outcome and one for the fallback.
- **Proof.** Save the output to `<run>/evidence/39-9-tests.txt` (or `/private/tmp/slotbar-verify/tests/` without a run).

## Gotchas

- Confirm the tests exercise the decision function, not a mock of it: read the test names against the four outcomes.
