# Terminal - spec

## Problem Statement

A Slotbar user who works in the terminal opens a separate terminal app every time they need a quick command. The Panel already gives instant access to web apps from any Space with one hotkey; a shell is the one tool it cannot hold. A web terminal served on localhost works in a Slot, but it needs an external server, an open local port, a manual setup and loses native keyboard handling.

## Solution

Slotbar has a built-in **Terminal**: a native terminal view living in the Panel next to the Slots. It is turned on from a dedicated Terminal page in Settings. When on, a fixed icon at the end of the Rail and a dedicated global hotkey open it. The Terminal holds several tabs, each running its own shell. It is never unloaded, so shells keep running while the Panel is hidden. Theme, font size, shell and starting directory are configurable. Nothing external is installed or started: no server, no port.

## User Stories

1. As a Slotbar user, I want to turn the Terminal on from Settings, so that I get a shell in the Panel only when I want one.
2. As a Slotbar user, I want the Terminal off by default, so that existing and new installs behave as before until I opt in.
3. As a Slotbar user, I want the Terminal settings on their own Settings page, so that they are easy to find and do not clutter General.
4. As a Slotbar user, I want a Terminal icon fixed at the end of the Rail, so that I can open it with one click.
5. As a Slotbar user, I want the Terminal icon to stay out of the Slot list, so that `Cmd+1..9` keep pointing at my web Slots.
6. As a Slotbar user, I want the Terminal icon to look different from Slot icons (no Profile color bar), so that I can tell it is not a web app.
7. As a Slotbar user, I want a tooltip on the Terminal icon showing its hotkey, so that I can learn the shortcut.
8. As a Slotbar user, I want a global hotkey that opens the Panel directly on the Terminal, so that I reach a shell from any app in one keystroke.
9. As a Slotbar user, I want the Terminal hotkey to switch to the Terminal when the Panel is showing a Slot, so that I do not have to click the Rail.
10. As a Slotbar user, I want the Terminal hotkey to hide the Panel when the Terminal is already shown and focused, so that the same key opens and closes it.
11. As a Slotbar user, I want to change the Terminal hotkey in Settings, so that it does not clash with my other apps.
12. As a Slotbar user, I want the Terminal hotkey unregistered while the Terminal is off, so that the key combination stays free for other apps.
13. As a Slotbar user, I want the Panel hotkey to reopen the Terminal when it was the last view I used, so that I resume where I left off.
14. As a Slotbar user, I want keyboard focus in the active tab whenever the Terminal is shown, so that I can type immediately.
15. As a Slotbar user, I want my shells to keep running while the Panel is hidden, so that long commands are not interrupted.
16. As a Slotbar user, I want the Terminal never unloaded after inactivity or under memory pressure, so that I never lose a session by surprise.
17. As a Slotbar user, I want turning the Terminal off to close all its shells, so that no hidden process keeps running.
18. As a Slotbar user, I want a confirmation before turning the Terminal off while a program is running in a tab, so that I do not kill it by mistake.
19. As a Slotbar user, I want to open a new tab with `Cmd+T`, so that I can run several shells side by side.
20. As a Slotbar user, I want the tab bar to appear only when there are two or more tabs, so that a single shell uses all the space.
21. As a Slotbar user, I want each tab titled with the title the shell sets, so that I can tell tabs apart by directory or running command.
22. As a Slotbar user, I want to switch tabs with `Cmd+Shift+[` and `Cmd+Shift+]`, so that I can move between them without the mouse.
23. As a Slotbar user, I want to click a tab to select it, so that mouse use works as in other terminal apps.
24. As a Slotbar user, I want a close button on a tab when hovering it, so that I can close it with the mouse.
25. As a Slotbar user, I want to double-click the empty part of the tab bar to open a new tab, so that I can add one with the mouse.
26. As a Slotbar user, I want `Cmd+W` to close the current tab, so that tab handling matches other terminal apps.
27. As a Slotbar user, I want `Cmd+W` on the last tab to replace it with a fresh shell and hide the Panel, so that the Terminal is never empty and `Cmd+W` still dismisses the Panel.
28. As a Slotbar user, I want a tab to close when its shell exits (`exit`, `Ctrl+D`), so that finished sessions do not linger.
29. As a Slotbar user, I want the last tab replaced by a fresh shell when its shell exits, with the Panel staying open, so that I can keep working.
30. As a Slotbar user, I want a confirmation before closing a tab where a program other than the shell is running, so that I do not kill `vim` or `ssh` by mistake.
31. As a Slotbar user, I want a confirmation on Quit when any tab runs a program other than the shell, so that I do not lose work by quitting.
32. As a Slotbar user, I want Quit without confirmation when every tab is idle at the prompt, so that quitting stays quick.
33. As a Slotbar user, I want `Cmd+R` to do nothing in the Terminal, so that a habit from web Slots does not disturb the shell.
34. As a Slotbar user, I want `Cmd+K` to clear the screen and scrollback of the current tab, so that I can start from a clean view.
35. As a Slotbar user, I want to pick a theme from a short built-in list, so that the Terminal matches my taste.
36. As a Slotbar user, I want a "Follow system" theme as the default, so that the Terminal is light or dark with macOS, live.
37. As a Slotbar user, I want to set the font size in Settings, so that text is readable on my screen.
38. As a Slotbar user, I want `Cmd+=`, `Cmd+-` and `Cmd+0` to enlarge, shrink and reset the font size, so that I can adjust it on the fly.
39. As a Slotbar user, I want SF Mono as the font, so that the Terminal looks native without configuration.
40. As a Slotbar user, I want the Terminal to start my login shell by default, so that my PATH and profile are loaded as in Terminal.app.
41. As a Slotbar user, I want to set a different shell executable in Settings, so that I can use fish or another shell.
42. As a Slotbar user, I want to set the starting directory in Settings, so that new tabs open where I work.
43. As a Slotbar user, I want shell and directory changes to apply to new tabs only, so that my running sessions are not touched.
44. As a Slotbar user, I want a tab to show a clear error when the configured shell cannot start, and to retry with Return, so that I can fix the setting and recover without restarting.
45. As a Slotbar user, I want Option to type characters as usual in macOS, so that I can type `@`, `#`, `[` and `]` on an Italian keyboard.
46. As a Slotbar user, I want to copy the selection with `Cmd+C` only, so that selecting text never overwrites my clipboard.
47. As a Slotbar user, I want `Cmd+V` to paste with bracketed paste, so that multi-line pastes do not run line by line.
48. As a Slotbar user, I want `Cmd+A` to select the whole scrollback of the tab, so that I can copy a full session.
49. As a Slotbar user, I want 10,000 lines of scrollback per tab, so that I can scroll back through long outputs.
50. As a Slotbar user, I want `Cmd`-click on a URL in the output to open it in my default browser, so that links from logs and tools are one click away.
51. As a Slotbar user, I want a dot on a tab and on the Terminal Rail icon when a hidden tab rings the bell, so that I notice when a long command finishes.
52. As a Slotbar user, I want the bell dot to clear when I look at the tab, so that it only signals new events.
53. As a Slotbar user, I want the bell to raise no macOS notification and no menu bar badge, so that the Terminal does not add noise.
54. As a Slotbar user, I want the Terminal to start with one fresh tab after a relaunch, so that startup is predictable.
55. As a Slotbar user, I want the Terminal to resize its rows and columns when I resize the Panel, so that full-screen programs redraw correctly.
56. As a Slotbar user, I want the Terminal on every Panel edge (left, right, top, bottom), so that it works with my Panel placement.

## Implementation Decisions

**Engine**
- Terminal emulation and the pty come from SwiftTerm (MIT), added as the second SwiftPM dependency. Each tab owns one local process view running the shell in a pty.
- The app has no App Sandbox, so spawning shells needs no entitlement.

**Domain**
- The **Terminal** is a new domain entity, separate from Slots: it has no URL, no Profile, no Keep-alive and no Notifications setting, and it is not in the Slot list. GLOSSARY.md gains **Terminal** and **Terminal tab** entries; Slot, Rail and Panel entries mention the Terminal where relevant.
- docs/SPEC.md is updated for the new dependency, the data model, the Rail, show/hide, the keyboard section and the Settings UI.

**Data model and persistence**
- Settings gains an optional `terminal` object. A settings file without it reads as the Terminal off with default values; `schemaVersion` does not change.
- Fields: `enabled` (bool, default false), `theme` (`system | solarizedLight | solarizedDark | dracula | nord`, default `system`), `fontSize` (number, default 13, range 9-36), `shellPath` (string or null, null means `$SHELL`), `startDirectory` (string or null, null means the home directory; a leading `~` expands to home).
- The Terminal hotkey is stored by KeyboardShortcuts in UserDefaults under shortcut name `toggleTerminal`, default `Ctrl+Option+T`, registered only while `enabled` is true.
- Tabs, titles, scrollback, the live font size and the last active view are memory only.

**Terminal session model (new module)**
- A pure value type owns the tab list, the active tab, each tab's title and bell flag. It takes events (open tab, select tab, next/previous tab, close tab requested, close confirmed, shell exited, bell received, Terminal shown/hidden, Terminal turned off) and returns effects for the controller to perform: spawn a shell, terminate a shell, ask for confirmation, hide the Panel.
- Starts with one tab. Never holds zero tabs while the Terminal is on.
- Close requested on a tab with a foreground process other than the shell yields "ask for confirmation"; otherwise the tab closes.
- Close on the last tab: replace it with a new tab and hide the Panel. Shell exit on the last tab: replace it with a new tab, Panel unchanged.
- Bell on a tab that is not visible (other tab active, or Terminal not shown) sets its flag; the flag clears when the tab becomes visible. The Rail icon shows the dot when any tab has the flag.
- "Foreground process other than the shell" is decided by comparing the pty's foreground process group with the shell's process id; the controller supplies this as a boolean per tab.

**Terminal controller**
- Owned by the AppDelegate, created when the Terminal is turned on, destroyed when it is turned off. Never unloaded by the Slot lifecycle rules or memory pressure.
- Spawns each tab's shell as a login shell (argv[0] prefixed with `-`) from `shellPath` or `$SHELL`, in `startDirectory` or home, with the app environment plus `TERM=xterm-256color`. Settings changes affect only tabs spawned afterwards.
- A shell that fails to start leaves the tab showing the error and "Press Return to try again"; Return respawns with the current settings.
- Turning the Terminal off or quitting with any busy tab asks for one confirmation listing the busy tabs' titles; on confirm, all shells are terminated.

**Panel, Rail and show/hide**
- The Panel's active view is either a Slot or the Terminal. The last active view is remembered in memory; if it is the Terminal and the Terminal has been turned off, show uses Slot 1.
- The Rail shows the Terminal item after all Slot items and before the gear, only while enabled: SF Symbol `terminal`, no Profile color bar, active highlight, bell dot, tooltip "Terminal" plus the hotkey. No right-click menu.
- Terminal hotkey decisions: Panel hidden, show it on the Terminal; Panel shown on a Slot or Settings, switch to the Terminal and make key; Panel shown on the Terminal but not key, make key; Panel shown on the Terminal and key, hide.
- When the Terminal becomes visible, its active tab becomes first responder.

**Keyboard**
- Panel shortcut matching takes whether the Terminal is the active view. With the Terminal active: `Cmd+T` new tab, `Cmd+W` close tab, `Cmd+Shift+[` / `Cmd+Shift+]` previous / next tab, `Cmd+K` clear, `Cmd+=` / `Cmd+-` / `Cmd+0` font larger / smaller / back to the Settings size, `Cmd+R` consumed with no action. `Cmd+1..9` and `Cmd+Shift+H` / `Cmd+Shift+O` keep their current meaning (the last two do nothing on the Terminal). With a Slot active, matching is unchanged.
- `Cmd+C` copies the selection, `Cmd+V` pastes with bracketed paste when the program enables it, `Cmd+A` selects the whole scrollback. Option composes characters; it is not a Meta key.
- Live font size changes apply to all tabs and are not saved.

**Appearance**
- Font: SF Mono at the configured size. Cursor: blinking block. Scrollback: 10,000 lines per tab.
- Themes are built-in color palettes (16 ANSI colors, foreground, background, cursor, selection). `system` uses a light or dark palette matching the effective appearance and switches live.
- `Cmd`-click on a URL in the output opens it with the default browser through macOS, bypassing link routing.

**Settings UI**
- A new "Terminal" page next to General, Profiles and Slots: Enable toggle, hotkey recorder, theme picker, font size stepper, shell path field (placeholder shows the current `$SHELL`), starting directory field (placeholder `~`). All controls except the toggle are disabled while the Terminal is off. Changes are written immediately, like the rest of Settings.

## Testing Decisions

- Tests use Swift Testing on pure logic, through the module's public interface, asserting outputs and effects, never internal state or private helpers. The pty, SwiftTerm views and AppKit windows are not tested.
- Terminal session model: every rule in the session model section, including `Cmd+W` versus shell exit on the last tab, confirmation only with a busy tab, bell flag set only on non-visible tabs and cleared on show, one tab at start. Prior art: SlotLifecycleTests.
- Panel shortcut matching: the Terminal-active mappings, and unchanged results with a Slot active. Prior art: PanelShortcutTests.
- Settings decoding: a file without `terminal` reads as off with defaults; encode then decode round-trips; out-of-range font size and unknown theme handling. Prior art: SettingsStoreTests.
- Show and toggle: the four Terminal hotkey outcomes; last active view falling back to Slot 1 when the Terminal is off. Prior art: PanelToggleTests, SlotSelectionTests.
- Rail items: Terminal item present only when enabled, always last, active flag, bell dot. Prior art: RailItemsTests.

## Out of Scope

- More than one Terminal, split panes, tab reordering.
- Restoring tabs, directories or scrollback after a relaunch.
- Importing color schemes, custom fonts, cursor styles, configurable scrollback.
- Option as Meta.
- Shell arguments or custom commands per tab.
- macOS notifications or menu bar badge from the Terminal.
- Routing Terminal URLs to Slots.

## Further Notes

- The Terminal adds no permission, no network listener and no helper executable to the app bundle.
- SwiftTerm must build with Swift 6 language mode in the package; if it does not, it is compiled in Swift 5 mode as a dependency while the Slotbar target stays in Swift 6.
