# Bell raises no notification or badge (#46, criterion 4)

The bell raises no macOS notification and no menu bar badge.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `46-4-no-notification` no notification is posted.
- `46-4-no-badge` the status item title stays empty.

## How to get to it (user POV)

- A hidden tab rings.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Ring hidden.** Type `sleep 3; printf '\a'` + Return, `Cmd+1`, `Cmd+W` (hide from a Slot; `Cmd+W` on the Terminal closes the tab). After 4 s:
- **No notification.** `V logs`: no line from category `Notifications` after the ring (the verify copy is not authorized for notifications, so the log is the proof, not Notification Center).
- **No badge.** The status item window width is unchanged from before the ring (no title text): it is owned by Control Centre and named after the bundle id; read it with `CGWindowListCopyWindowInfo([.optionAll], ...)` filtered on `kCGWindowName == io.github.mogui.slotbar.verify` (34 pt wide without a badge).

## Gotchas

- Code path: bell -> `ShellTerminalView.bell` -> `TerminalController.handle(.bell)` -> `onBellChange` -> `PanelController.refreshRail`; nothing reaches NotificationBridge or BadgeAggregator.
- A system beep is audible (SwiftTerm default, approved); it is not a notification.
- The verify copy's notification authorization fails ("Notifications are not allowed for this application"); a missing banner proves nothing, the absence of a post attempt in the code path/logs does.
- `V shot` and `windows.swift <pid>` do not see the status item: its window belongs to Control Centre, not to the app's pid.
