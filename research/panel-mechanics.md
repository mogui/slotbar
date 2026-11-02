# Panel mechanics on macOS

Research for [#7](https://github.com/mogui/slotbar/issues/7) (map [#1](https://github.com/mogui/slotbar/issues/1)).
Question: how to build the Panel natively - shown over full-screen apps and on all Spaces, sliding from any of the 4 edges, auto-hiding on focus loss, opened by a global hotkey, in a menu-bar-only app - and whether Accessibility or Input Monitoring permission is needed.

Sources checked on 2026-11-02. SDK headers are from the local Xcode macOS SDK 27.0. Open-source code is cited at a pinned commit.

## Answer

| Concern | Native mechanism | Permission |
|---|---|---|
| Window type | `NSPanel` subclass, `styleMask` includes `.nonactivatingPanel`, `.titled` removed, `canBecomeKey`/`canBecomeMain` overridden to `true` | none |
| All Spaces + over full-screen apps | `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`, app runs as `LSUIElement` / `.accessory` | none |
| Window level | `.popUpMenu` while sliding (allows off-screen start, sits above menu bar and Dock), then `.floating` once shown | none |
| Slide from an edge | `NSAnimationContext.runAnimationGroup` + `window.animator().setFrame(...)`, start origin just outside `screen.visibleFrame` on the chosen edge | none |
| Focus-loss auto-hide | `NSWindowDelegate.windowDidResignKey(_:)`, skipped while a sheet is attached; reactivate the previously frontmost app on hide | none |
| Global hotkey | Carbon `RegisterEventHotKey` (directly or through `sindresorhus/KeyboardShortcuts`) | none |
| Menu bar only | `LSUIElement = 1` in `Info.plist` (same as `NSApplication.ActivationPolicy.accessory`) | none |

You only need Accessibility if global keys are read with `CGEventTap` or `NSEvent.addGlobalMonitorForEvents` instead of `RegisterEventHotKey`. A listen-only event tap needs Input Monitoring instead. The Panel needs neither.

## 1. Window type: non-activating `NSPanel`

- The `NSWindowStyleMaskNonactivatingPanel` style mask "Specifies that a panel that does not activate the owning application. Only applicable for `NSPanel` (or a subclass thereof)." Source: `AppKit.framework/Headers/NSWindow.h`. Apple docs: [nonactivatingPanel](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel).
- `canBecomeKey` is `true` only if the style mask includes `.titled`. To make a window key without `.titled`, a subclass must override it to return `true` ([canBecomeKey](https://developer.apple.com/documentation/appkit/nswindow/canbecomekey)).
- `NSPanel.hidesOnDeactivate` defaults to `true`, while `NSWindow` defaults to `false` ([hidesOnDeactivate](https://developer.apple.com/documentation/appkit/nswindow/hidesondeactivate)). Set it explicitly so hiding follows Slotbar's own toggleable auto-hide rule.
- `becomesKeyOnlyIfNeeded` (default `false`): "If the panel is a non-activating panel, then it becomes key only if the hit view returns true from `needsPanelToBecomeKey`" ([becomesKeyOnlyIfNeeded](https://developer.apple.com/documentation/appkit/nspanel/becomeskeyonlyifneeded)). Leave it `false`, because the Panel hosts web apps that need the keyboard.
- Prior art: Ghostty's quick terminal is exactly this kind of `NSPanel` subclass. It removes `.titled`, inserts `.nonactivatingPanel`, overrides `canBecomeKey`/`canBecomeMain` to `true`, and sets AX subrole `.floatingWindow` so tiling window managers float it. See [QuickTerminalWindow.swift@0b1729e](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/QuickTerminal/QuickTerminalWindow.swift).

## 2. All Spaces and over full-screen apps

`NSWindowCollectionBehavior` in `NSWindow.h`, with the macOS version each flag appeared:

| Flag | Meaning (header / docs) | Since |
|---|---|---|
| `canJoinAllSpaces` | "The window can appear in all spaces. The menu bar behaves this way." | 10.5 |
| `moveToActiveSpace` | window moves to the active Space when made visible | 10.5 |
| `transient` / `stationary` | transient "Floats in spaces, hidden by exposé" (default when level is not normal) | 10.6 |
| `ignoresCycle` | not in the window cycle (default when level is not normal) | 10.6 |
| `fullScreenAuxiliary` | "Windows with this collection behavior can be shown with the fullscreen window." | 10.7 |
| `primary` / `auxiliary` / `canJoinAllApplications` | Stage Manager roles. `canJoinAllApplications`: "allowing it to join other apps' sets and full screen spaces when eligible ... floating windows and system overlays" | 13.0 |

Sources: `NSWindow.h`, [fullScreenAuxiliary](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/fullscreenauxiliary), [canJoinAllSpaces](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallspaces), [canJoinAllApplications](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallapplications).

### The macOS 10.14+ catch

Electron's native code says that since 10.14 an ordinary app's window can no longer float over another app's full-screen Space. Electron works around this by turning the process into a UI element (`app.dock.hide()`) before it sets `canJoinAllSpaces` and `fullScreenAuxiliary`:

> "In order for NSWindows to be visible on fullscreen we need to invoke app.dock.hide() since Apple changed the underlying functionality of NSWindows starting with 10.14 to disallow NSWindows from floating on top of fullscreen apps."
> - [electron `shell/browser/native_window_mac.mm` `SetVisibleOnAllWorkspaces`](https://github.com/electron/electron/blob/main/shell/browser/native_window_mac.mm)

Electron's `type: 'panel'` option instead "enables the window to float on top of full-screened apps by adding the `NSWindowStyleMaskNonactivatingPanel` style mask ... Also, the window will appear on all spaces" ([base-window-options.md](https://github.com/electron/electron/blob/main/docs/api/structures/base-window-options.md)).

For Slotbar this means the two working recipes are an `LSUIElement` app and a non-activating `NSPanel`. Slotbar is both, so it is covered twice. Apple does not document this rule. It comes from Electron's code comment and from how the open-source apps below behave.

### Prior-art configurations

- Ghostty, "move" mode (follows you to the active Space): `[.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]`. "remain" mode: `[.moveToActiveSpace, .ignoresCycle, .fullScreenAuxiliary]`. See [QuickTerminalSpaceBehavior.swift@0b1729e](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/QuickTerminal/QuickTerminalSpaceBehavior.swift).
- iTerm2 hotkey window: after a display reconfiguration (lid close/open on multi-monitor), macOS can pin a `canJoinAllSpaces` window to a single Space. Ordering it front then switches Spaces. The workaround clears `canJoinAllSpaces`, orders the window front, and restores the flag on the next runloop spin. "macOS coalesces collectionBehavior changes made within a single runloop iteration" ([iTermProfileHotKey.m@095beb4](https://github.com/gnachman/iTerm2/blob/095beb457dca2a5ed4a9f155dc2b4dc7d9ef34a2/sources/Hotkey/iTermProfileHotKey.m), `prepareJoinsAllSpacesWindowForRollInOnActiveSpace`).

## 3. Window level

Named levels in `NSWindow.h`: `normal`, `floating`, `submenu`/`tornOffMenu`, `mainMenu`, `status`, `modalPanel`, `popUpMenu`, `screenSaver`.

- Ghostty switches to `.popUpMenu` for the slide: "In testing, only popUpMenu and above do what we want. This gets it above the menu bar and lets us render off screen." After the slide it drops to `.floating` "so things like IME dropdowns appear properly" ([QuickTerminalController.swift@0b1729e](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/QuickTerminal/QuickTerminalController.swift), `animateWindowIn`).
- iTerm2's notes on levels: menu bar/Dock = `mainMenu` (24), Notification Center = 23 (macOS 11+), and 21-23 are unnamed. `tornOffMenu` is under the Dock. `status` (25) covers an auto-hidden menu bar. iTerm2 uses `mainMenu - 2` (22) "just below notifications" for most hotkey windows ([iTermProfileHotKey.m@095beb4](https://github.com/gnachman/iTerm2/blob/095beb457dca2a5ed4a9f155dc2b4dc7d9ef34a2/sources/Hotkey/iTermProfileHotKey.m)).
- Electron's docs agree: levels `floating` through `status` sit below the Dock, and `pop-up-menu` and higher sit above it ([base-window.md `setAlwaysOnTop`](https://github.com/electron/electron/blob/main/docs/api/base-window.md)).

## 4. Slide animation from any edge

- Ghostty supports `top`, `bottom`, `left`, `right`, and `center`. Before the slide it puts the window just outside `screen.visibleFrame` on the chosen edge. For example, `left` uses `x = visibleFrame.minX - width` and `right` uses `x = visibleFrame.maxX`, both centered on the other axis. It then animates to the final origin inside `visibleFrame` ([QuickTerminalPosition.swift@0b1729e](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/QuickTerminal/QuickTerminalPosition.swift)).
- Animation: `NSAnimationContext.runAnimationGroup { ctx.duration = ...; ctx.timingFunction = .easeIn; position.setFinal(in: window.animator(), ...) }`. Hiding animates back to the initial origin and then calls `orderOut`. If the window is not on the active Space it skips the animation and calls `orderOut` directly (`animateWindowIn` / `animateWindowOut`, same file).
- Ghostty auto-hides the Dock when the slide position would collide with it, and restores the Dock on focus loss (`hiddenDock`, same file).
- Ghostty's macOS 13 Ventura workaround: SwiftUI hosting can corrupt the first `setFrame` (sometimes to zero size), so it caches `initialFrame` ([QuickTerminalWindow.swift](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/QuickTerminal/QuickTerminalWindow.swift), [PR #8026](https://github.com/ghostty-org/ghostty/pull/8026)).

## 5. Showing, focus, and auto-hide on focus loss

- Show: `makeKeyAndOrderFront`, then `makeFirstResponder(view)` after the slide finishes. If `!NSApp.isActive`, Ghostty also calls `NSApp.activate(ignoringOtherApps: true)` and retries `makeKey` up to 10 times at 25 ms intervals, because on a screen with no other app windows the window can take several event-loop ticks to become key ([ghostty#2409](https://github.com/ghostty-org/ghostty/issues/2409); `makeWindowKey` in QuickTerminalController.swift).
- On show, record `NSWorkspace.shared.frontmostApplication`. On hide, call `previousApp.activate(options: [])` before the slide out, "because when the animation completes macOS will bring forward another window" (`animateWindowOut`).
- Auto-hide: `windowDidResignKey(_:)`. Return early if the window is not visible or `window.attachedSheet != nil`, so alerts and sheets don't dismiss the Panel. When following Spaces (`canJoinAllSpaces`), compare the active Space before and after. A Space switch re-shows the Panel instead of hiding it. Ghostty reads the active Space through the private `CGSSpace` wrapper (`windowDidResignKey`, QuickTerminalController.swift).
- Activation on macOS 14+: `activateIgnoringOtherApps:` is marked "will be deprecated ... Use NSApp.activate instead". `-activate` (macOS 14.0) "does not guarantee that the app will be activated at all", and cooperative activation expects the other app to call `yieldActivation(to:)` first (`NSApplication.h`). A non-activating panel avoids most of this because it can become key without activating the app.
- Detecting a click outside the Panel without a key-window change: `NSEvent.addGlobalMonitorForEvents` for mouse events works without permission. Only "Key-related events may only be monitored if accessibility is enabled or if your application is trusted for accessibility access" (`NSEvent.h`).

## 6. Global hotkey

### Carbon `RegisterEventHotKey`

From `HIToolbox.framework/Headers/CarbonEvents.h`:
- Available "Mac OS X 10.0 and later". It is declared outside the `!__LP64__` block, so it is available to 64-bit apps and is not marked deprecated in SDK 27.0.
- "Registers a global hot key based on the virtual key code and modifiers ... The same hot key can, however, be registered by multiple applications." `kEventHotKeyExclusive` (10.5+) blocks non-exclusive registrants, and registering an exclusive combo that is already taken returns `eventHotKeyExistsErr`.
- Delivery: a `kEventClassKeyboard`/`kEventHotKeyPressed` event goes to an `InstallEventHandler` handler.
- It reads no keystrokes beyond the registered combo, so no TCC permission is involved.

### Libraries and frameworks built on it

| Library | Mechanism | Permission | Notes |
|---|---|---|---|
| [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | `RegisterEventHotKey` on `GetEventDispatcherTarget()` (`Sources/KeyboardShortcuts/HotKey.swift`) | README FAQ: "Does this package cause any permission dialogs? No." | macOS 10.15+, sandbox and App Store compatible, includes a SwiftUI/Cocoa `Recorder` for the settings UI, checks for shortcuts already taken by the system |
| Chromium / Electron `globalShortcut` | `RegisterEventHotKey` + `InstallApplicationEventHandler` ([global_accelerator_listener_mac.mm](https://chromium.googlesource.com/chromium/src/+/main/ui/base/accelerators/global_accelerator_listener/global_accelerator_listener_mac.mm)) | none, except media keys, which need a "trusted accessibility client" since 10.14 ([global-shortcut.md](https://github.com/electron/electron/blob/main/docs/api/global-shortcut.md)) | |
| Tauri `global-shortcut` plugin -> [tauri-apps/global-hotkey](https://github.com/tauri-apps/global-hotkey) | `RegisterEventHotKey`, plus a `CGEventTapCreate` only for media keys (`src/platform_impl/macos/mod.rs`) | none for normal combos | |
| iTerm2 hotkey window | `RegisterEventHotKey` ([iTermCarbonHotKeyController.m](https://github.com/gnachman/iTerm2/blob/095beb457dca2a5ed4a9f155dc2b4dc7d9ef34a2/sources/Hotkey/iTermCarbonHotKeyController.m)) | none | |
| Ghostty `keybind = global:...` | `CGEvent.tapCreate`, gated on `AXIsProcessTrusted()` with a prompt ([GlobalEventTap.swift@0b1729e](https://github.com/ghostty-org/ghostty/blob/0b1729e945978fca4bcd6165d8ac408bf675a7f2/macos/Sources/Features/Global%20Keybinds/GlobalEventTap.swift)) | Accessibility | Counterexample: the event tap is why Ghostty asks for permission |

### macOS 15.0-15.1 caveat

KeyboardShortcuts disallows hotkeys whose only modifiers are Option or Option+Shift on macOS 15.0 and 15.1 when the app is sandboxed: "It only handles a bug present in sandboxed apps on macOS 15.0 and 15.1" (`Shortcut.swift`, `isDisallowed`). Slotbar ships as an unsigned, non-sandboxed `.app` and should not be affected. Pick a default that includes Cmd or Ctrl anyway.

## 7. Menu-bar-only app

- `LSUIElement`: "A Boolean value indicating whether the app is an agent app that runs in the background and doesn't appear in the Dock." Available since macOS 10.0 ([LSUIElement](https://developer.apple.com/documentation/bundleresources/information-property-list/lsuielement)).
- `NSApplication.ActivationPolicy.accessory`: "doesn't appear in the Dock and doesn't have a menu bar, but it may be activated programmatically or by clicking on one of its windows. This corresponds to ... `LSUIElement` ... `1`." Since 10.9 the policy can be switched to `.accessory` at runtime with `setActivationPolicy(_:)`. Before 10.9 it could not (`NSApplication.h`, `NSRunningApplication.h`).
- Electron warns that its runtime process-type change "will hide the window and dock for a short time every time it is called" ([base-window.md `setVisibleOnAllWorkspaces`](https://github.com/electron/electron/blob/main/docs/api/base-window.md)). Setting `LSUIElement` statically in `Info.plist` avoids that.

## 8. Permissions summary

| API | TCC permission | Source |
|---|---|---|
| `RegisterEventHotKey` | none | KeyboardShortcuts FAQ, Chromium and Tauri implementations |
| `NSPanel`, collection behaviors, levels, `LSUIElement` | none | AppKit headers (no TCC mention) |
| `NSEvent.addGlobalMonitorForEvents` (mouse) | none | `NSEvent.h` |
| `NSEvent.addGlobalMonitorForEvents` (keys) | Accessibility (`AXIsProcessTrusted`) | `NSEvent.h` |
| `CGEventTap` listen-only | Input Monitoring: `CGPreflightListenEventAccess` / `CGRequestListenEventAccess`, macOS 10.15+ | `CoreGraphics.framework/Headers/CGEvent.h` |
| `CGEventTap` that can modify events / AX window control | Accessibility | Ghostty `GlobalEventTap.swift` |

The recommended design asks for no permission at all.

## 9. Electron and Tauri equivalents

| Need | Electron | Tauri v2 |
|---|---|---|
| Panel window | `new BrowserWindow({ type: 'panel' })` adds `NonactivatingPanel` and all-Spaces | core has no `NSPanel`. Use [ahkohd/tauri-nspanel](https://github.com/ahkohd/tauri-nspanel) (`PanelBuilder`, `StyleMask::nonactivating_panel()`, `CollectionBehavior::can_join_all_spaces()`, `PanelLevel`) |
| All Spaces + full screen | `win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })` -> `canJoinAllSpaces` + `fullScreenAuxiliary` + `DockHide` | `visibleOnAllWorkspaces` window config sets only `canJoinAllSpaces` ([tao `set_visible_on_all_workspaces`](https://github.com/tauri-apps/tao/blob/dev/src/platform_impl/macos/window.rs)). `fullScreenAuxiliary` needs tauri-nspanel or raw `objc2` |
| Level | `win.setAlwaysOnTop(true, 'pop-up-menu')` | `PanelLevel` in tauri-nspanel, or `alwaysOnTop` (floating) |
| Menu bar only | `app.dock.hide()` / `app.setActivationPolicy('accessory')` / `LSUIElement` | `app.set_activation_policy(ActivationPolicy::Accessory)` |
| Hotkey | `globalShortcut.register` (Carbon) | `tauri-plugin-global-shortcut` (Carbon via `global-hotkey`) |

All three stacks reach the same AppKit flags and the same Carbon call. A native app uses them directly, without a bridge.

## 10. macOS version caveats

- 10.5: `canJoinAllSpaces`, `moveToActiveSpace`. 10.6: `transient`/`stationary`/`ignoresCycle`. 10.7: `fullScreenAuxiliary`.
- 10.9: activation policy can be switched to `.accessory` at runtime.
- 10.14: windows of ordinary apps stop floating over full-screen Spaces. Use `LSUIElement` and/or a non-activating panel (Electron comment). Electron/Chromium media-key hotkeys need Accessibility.
- 10.15: Input Monitoring TCC for listen-only event taps. Minimum version for KeyboardShortcuts.
- 13.0: Stage Manager collection behaviors (`primary`, `auxiliary`, `canJoinAllApplications`). Ghostty has a SwiftUI frame bug workaround on Ventura.
- 14.0: cooperative activation. `NSApp.activate()` is not guaranteed and `activateIgnoringOtherApps:` is slated for deprecation.
- 15.0-15.1: Option-only / Option+Shift Carbon hotkeys fail in sandboxed apps (fixed by 15.2 per KeyboardShortcuts).
- Any version: after display reconfiguration, a `canJoinAllSpaces` window can get pinned to one Space (iTerm2 issue 12968 workaround).

## Open questions for the Panel behaviour ticket

1. Space mode: should the Panel follow you to the active Space (`canJoinAllSpaces`, Ghostty "move") or stay on the Space where it was opened (`moveToActiveSpace`, "remain")?
2. Auto-hide exceptions: file-upload `NSOpenPanel`, download save panels, JS alerts, passkey/WebAuthn sheets, and Google login pop-ups (`window.open`) all take key status. Which ones must not dismiss the Panel, and how is each detected (`attachedSheet` only covers sheets)?
3. Status bar icon click while the Panel is shown: the click makes the Panel resign key, which triggers auto-hide, and then the toggle re-shows it. The toggle needs to be debounced against auto-hide.
4. Multi-monitor: should the Panel open on the screen under the mouse, the screen with the key window (`NSScreen.main`), or a fixed screen?
5. Size per edge: fixed or percentage of `visibleFrame`, user-resizable, remembered per screen (Ghostty caches the frame per screen)?
6. Dock collision: should the Panel auto-hide the Dock like Ghostty, or sit at a level above it (`.popUpMenu`) and cover it?
7. Keyboard in a non-activating panel: confirm with a prototype that WKWebView text input, Gmail single-key shortcuts and `Cmd+1..N` key equivalents all work while the app is not active. Without a visible main menu, `Cmd+N` may need a local `NSEvent` monitor or a `performKeyEquivalent` override.
8. Default global hotkey combination (must include Cmd or Ctrl), and how to handle conflicts (`eventHotKeyExistsErr`, system-taken shortcuts).
