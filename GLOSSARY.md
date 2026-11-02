# Glossary

**Slot**
A configured pairing of a starting URL with one Profile. Its position in the ordered Slot list is N; the first nine are reachable with `Cmd+1..9`. Several Slots may share the same URL and Profile.
_Avoid_: tab, service

**Profile**
An isolated browsing session tied to one Google account, identified by a name and a color. Several Slots can share one Profile; Slots in different Profiles never share cookies or storage.
_Avoid_: session, account

**Panel**
The window that slides in from a configurable screen edge, on the screen under the pointer, on the global hotkey or a click on the status bar icon; it shows the Rail and the active Slot.
_Avoid_: popup, browser window

**Keep-alive**
A per-Slot setting: a kept-alive Slot loads at launch and stays loaded while hidden so it can deliver notifications and unread counts; otherwise it loads only when opened and unloads after a 5-minute grace period hidden with no open child windows (or at once under memory pressure).

**Home host**
The host of a Slot's starting URL. Main-frame navigations to it stay in the Slot; navigations to other hosts go to a Slot of the same Profile with that home host, or to the default browser.

**Sign-in mode**
A temporary Slot state entered when the Slot navigates to a Google sign-in host; while active, every navigation and popup stays in the Slot, until it is back on its home host or ten minutes pass.

**Unloaded**
The state of a Slot whose page has been destroyed to free memory; it keeps only its settings and, until app quit, its last URL on its home host, where it reopens.
_Avoid_: suspended, sleeping

**Rail**
The always-visible strip along the Panel's outer side holding one icon per Slot in list order (favicon, Profile-color indicator, unread badge); clicking an icon makes its Slot active, right-clicking offers Go home, Open current page in browser, Reload and the Slot's Notifications toggle.
_Avoid_: tab bar, sidebar, dock

**Child window**
A native titled window opened by a Slot for a popup that stays in the app (same Profile, real `window.opener`); it floats with the Panel, hides and reappears with it, and closes when its Slot is unloaded, crashes or is deleted.
_Avoid_: popup, tab

**Notifications (Slot setting)**
A per-Slot toggle, on by default: when off, the Slot's notifications (including its child windows') are dropped by the app while the page still sees permission granted; the Slot's unread state still counts in the badge.
_Avoid_: mute, do not disturb

**Unread state**
What a loaded Slot reports to the badge: a count N, "count unknown" (unread exists, number not known, shown as a dot), or none; a failing source keeps the last known value. The status bar badge sums counts once per Profile and home host and adds a dot when any Slot is "count unknown"; Unloaded Slots contribute nothing.
_Avoid_: unread count (when the number may be unknown)
