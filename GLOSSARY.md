# Glossary

**Slot**
A configured pairing of a starting URL with one Profile. Its position in the ordered Slot list is N; the first nine are reachable with `Cmd+1..9`. Several Slots may share the same URL and Profile.
_Avoid_: tab, service

**Profile**
An isolated browsing session tied to one Google account, identified by a name and a color. Several Slots can share one Profile; Slots in different Profiles never share cookies or storage.
_Avoid_: session, account

**Panel**
The window that slides in from a configurable screen edge on the global hotkey or a click on the status bar icon, and shows the active Slot.
_Avoid_: popup, browser window

**Keep-alive**
A per-Slot setting: a kept-alive Slot stays loaded while the Panel is hidden so it can deliver notifications and unread counts; otherwise it loads only when opened.

**Home host**
The host of a Slot's starting URL. Main-frame navigations to it stay in the Slot; navigations to other hosts go to a Slot of the same Profile with that home host, or to the default browser.

**Sign-in mode**
A temporary Slot state entered when the Slot navigates to a Google sign-in host; while active, every navigation and popup stays in the Slot, until it is back on its home host or ten minutes pass.
