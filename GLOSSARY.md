# Glossary

**Slot**
A fixed pairing of one web service (Gmail, Google Calendar, Google Chat) with one Profile, bound to a position N reachable with `Cmd+N`.
_Avoid_: tab

**Profile**
An isolated browsing session tied to one Google account. Several Slots can share one Profile; Slots in different Profiles never share cookies or storage.
_Avoid_: session, account

**Panel**
The window that slides in from a configurable screen edge on the global hotkey or a click on the status bar icon, and shows the active Slot.
_Avoid_: popup, browser window

**Keep-alive**
A per-Slot setting: a kept-alive Slot stays loaded while the Panel is hidden so it can deliver notifications and unread counts; otherwise it loads only when opened.
