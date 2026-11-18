# Bell raises no notification or badge (#46, criterion 4)

The bell raises no macOS notification and no menu bar badge.

Status: pending

## Sub-features

- `46-4-no-notification` no notification is posted.
- `46-4-no-badge` the status item title stays empty.

## How to get to it (user POV)

- A hidden tab rings.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Ring hidden.** Type `sleep 3; printf '\a'` + Return, `Cmd+W`. After 4 s:
- **No notification.** `V logs`: no line from category `Notifications` after the ring (the verify copy is not authorized for notifications, so the log is the proof, not Notification Center).
- **No badge.** `V doctor` window list: the status item window width unchanged from before the ring (no title text); or a menu bar shot of the status item taken with the user's consent.

## Gotchas

- Code path: bell -> `ShellTerminalView.bell` -> `TerminalController.handle(.bell)` -> `onBellChange` -> `PanelController.refreshRail`; nothing reaches NotificationBridge or BadgeAggregator.
- A system beep is audible (SwiftTerm default, approved); it is not a notification.
- The verify copy's notification authorization fails ("Notifications are not allowed for this application"); a missing banner proves nothing, the absence of a post attempt in the code path/logs does.
- `V shot` skips windows under 60 pt, which includes the status item; use `swift .claude/skills/verify/scripts/windows.swift <pid>` to read its width.
