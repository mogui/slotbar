# Slotbar - implementable spec

Slotbar is a macOS menu bar app that shows Gmail, Google Calendar and Google Chat (or any web app) in a Panel that slides in from a screen edge. Each Google account is an isolated Profile. Terms in **bold** are defined in [GLOSSARY.md](../GLOSSARY.md). Each section links the tickets it comes from on the map [Slotbar: map to an implementable spec](https://github.com/mogui/slotbar/issues/1).

## 1. Stack

Sources: [Choose the stack](https://github.com/mogui/slotbar/issues/8), [RAM footprint per stack](https://github.com/mogui/slotbar/issues/5), [Persistent session isolation per Profile](https://github.com/mogui/slotbar/issues/3), [Google login inside an embedded webview](https://github.com/mogui/slotbar/issues/4)

| Topic | Decision |
|---|---|
| Language / UI | Swift 6 (language mode 6), AppKit, WKWebView. |
| SwiftUI | Only for the content of Settings, hosted in the Panel via `NSHostingController`. There is no `MenuBarExtra` and no `Settings` scene. |
| Minimum macOS | 14 Sonoma (`WKWebsiteDataStore(forIdentifier:)`). Tested on 26.x. 14 and 15 are best effort, and OS-version branches are added only for reported bugs. |
| Dependencies | Exactly one: [`sindresorhus/KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) (Carbon `RegisterEventHotKey` + recorder UI), via SwiftPM. |
| User agent | Hardcoded desktop Firefox-on-macOS UA set as `customUserAgent` on every webview (Slots and Child windows): `Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:<V>.0) Gecko/20100101 Firefox/<V>.0`, where `<V>` is the current Firefox release at build time and is bumped with releases. Hidden override: `defaults write io.github.mogui.slotbar UserAgent "<string>"`, read at launch; empty or missing uses the constant. No Settings field. |
| Web Inspector | `isInspectable = true` in Debug builds (`#if DEBUG`), `false` in Release. Compile time only. |
| Passkeys / security keys | Unsupported (unsigned app lacks the browser WebAuthn entitlement). Users sign in with password + 2FA via "Try another way". |
| Permissions | None. No Accessibility, no Input Monitoring, no App Sandbox, no entitlements, no hardened runtime. |

## 2. Architecture and modules

Sources: [Build and release pipeline](https://github.com/mogui/slotbar/issues/16), [Choose the stack](https://github.com/mogui/slotbar/issues/8)

SwiftPM package, one executable target `Slotbar` (`swift-tools-version: 6.0`, `platforms: [.macOS(.v14)]`). Folders under `Sources/Slotbar/`:

| Folder | Contents |
|---|---|
| `App/` | Entry point, `AppDelegate` (`NSApplication.ActivationPolicy.accessory` via `LSUIElement`, `.regular` with Show in Dock), hidden main menu (section 9), status item and its menu (section 4.6), location guard and Open at login (section 12.5). |
| `Model/` | `Settings`, `Profile`, `Slot`, `General` structs (`Codable`), `SettingsStore` (JSON I/O, change publishing), first-run preset. |
| `Panel/` | `PanelWindow` (`NSPanel` subclass), `PanelController` (show/hide, slide, resize, screen and Space handling), `RailView`. |
| `Slots/` | `SlotController` (one per Slot: webview, lifecycle state machine, grace timer, crash counter, reopen URL, sign-in mode), `ProfileStores` (one `WKWebsiteDataStore` per Profile, deletion queue). |
| `Web/` | `WebViewFactory` (configuration, UA, user scripts, inspector flag), `NavigationRouter` (link routing), `ChildWindowController`, `DownloadManager`, `UIDelegate` (JS dialogs, file pickers, media capture). |
| `Notifications/` | `NotificationBridge` (`WKScriptMessageHandlerWithReply` to `UNUserNotificationCenter`), de-dup, click routing. |
| `Unread/` | `UnreadAdapter` protocol and the Gmail, Chat and title-count adapters, `BadgeAggregator`, status item rendering. |
| `Settings/` | SwiftUI views for General, Profiles, Slots. |

`Resources/` at the package root (copied by `scripts/build-app.sh`, loaded from `Bundle.main`, no SwiftPM `resources:`): `Info.plist`, `AppIcon.icns` and its source PNG, the status bar template image, `notification-shim.js`, `unread-gmail.js`, `unread-chat.js`, `unread-title.js`, `favicon.js`.

Test target `SlotbarTests` (`Tests/SlotbarTests/`, `@testable import Slotbar`): pure-logic unit tests for `NavigationRouter`, `BadgeAggregator`, notification de-dup and `SettingsStore` decoding, run locally with `swift test`. If `@testable import` of the executable target fails with the runner's toolchain, the test target is dropped (no library target is added).

Runtime ownership:
- `AppDelegate` owns `SettingsStore`, `ProfileStores`, `PanelController`, `NotificationBridge`, `BadgeAggregator` and one `SlotController` per Slot, in list order.
- A `SlotController` owns its `WKWebView` (when loaded) and its Child windows. All webviews of one Profile share that Profile's `WKWebsiteDataStore`.
- Settings changes flow from `SettingsStore` to the controllers. The Settings UI and the Rail menu write through `SettingsStore` only.

## 3. Data model and persistence

Sources: [Settings data model and UI](https://github.com/mogui/slotbar/issues/10), [Notification behaviour](https://github.com/mogui/slotbar/issues/12), [Panel behaviour](https://github.com/mogui/slotbar/issues/9), [Persistent session isolation per Profile](https://github.com/mogui/slotbar/issues/3), [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14)

### 3.1 Entities

**Profile**
- `id`: UUID created with the Profile. It keys the Profile's `WKWebsiteDataStore(forIdentifier:)`.
- `name`: string.
- `color`: one of the palette colors (section 10.2), stored as `#RRGGBB`. A hex not in the palette (hand-edited JSON) is shown as is.
- No email, no credentials.

**Slot**
- `id`: UUID created with the Slot. It is used for notification threads, the favicon cache and runtime routing.
- `url`: starting URL, absolute `http`/`https`. Its host is the Slot's **Home host**.
- `profileId`: an existing Profile id.
- `label`: string or `null`. When it is `null`, the first completed load sets it to `<page title> - <Profile name>` and persists it. After that it is frozen and editable.
- `keepAlive`: bool, default `true`.
- `notifications`: bool, default `true`.
- Duplicates (same URL and Profile) are allowed.
- Position in `slots[]` is the list order. The Slot at position N (1-based, N <= 9) is reachable with `Cmd+N`.
- The icon is not stored in the model (section 4.4).

**General**
- `panelEdge`: `left | right | top | bottom`, default `right`.
- `hideOnFocusLoss`: bool, default `true`.
- `openAtLogin`: bool, default `false`. This is the user's choice; the actual registration state always comes from `SMAppService.mainApp.status`, and the launch self-heal reads both (section 12.5).
- `showInDock`: bool, default `false`. Optional key; a file without it reads as `false`.
- `panelDepth`: `{ horizontal, vertical }` fractions of the screen dimension. `horizontal` is the width for left/right (default `0.45`), `vertical` is the height for top/bottom (default `0.70`).

### 3.2 Storage

| What | Where |
|---|---|
| Settings | `~/Library/Application Support/Slotbar/settings.json` |
| Favicon cache | `~/Library/Application Support/Slotbar/favicons/<slot-id>.png` |
| Global hotkey | `UserDefaults`, owned by KeyboardShortcuts, shortcut name `togglePanel` |
| UA override | `UserDefaults` key `UserAgent` (hidden) |
| Pending store deletions | `UserDefaults` key `PendingStoreDeletions` (array of Profile UUID strings) |
| Profile session data | WebKit, `~/Library/WebKit/io.github.mogui.slotbar/WebsiteDataStore/<UUID>/` |
| Last URL per Slot, last active Slot, crash counters, Unread state | Memory only |
| Notification authorization | Never stored; read from `UNUserNotificationCenter` |

Rules:
- Every change is written immediately with `Data.write(to:options: .atomic)`, pretty printed with sorted keys.
- If the file is missing at launch, the first-run preset is written (section 11).
- If the file cannot be parsed or `schemaVersion` is unknown, the file is renamed to `settings.corrupt-<yyyyMMdd-HHmmss>.json` and the app starts from the first-run preset. The old Profiles' data stores stay on disk untouched; the user signs in again in the new preset Profile.
- On load, Slots whose `profileId` does not match a Profile are dropped and the file is rewritten.

### 3.3 JSON schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Slotbar settings",
  "type": "object",
  "required": ["schemaVersion", "general", "profiles", "slots"],
  "additionalProperties": false,
  "properties": {
    "schemaVersion": { "const": 1 },
    "general": {
      "type": "object",
      "required": ["panelEdge", "hideOnFocusLoss", "openAtLogin", "panelDepth"],
      "additionalProperties": false,
      "properties": {
        "panelEdge": { "enum": ["left", "right", "top", "bottom"], "default": "right" },
        "hideOnFocusLoss": { "type": "boolean", "default": true },
        "openAtLogin": { "type": "boolean", "default": false },
        "showInDock": { "type": "boolean", "default": false },
        "panelDepth": {
          "type": "object",
          "required": ["horizontal", "vertical"],
          "additionalProperties": false,
          "properties": {
            "horizontal": { "type": "number", "exclusiveMinimum": 0, "maximum": 0.95, "default": 0.45 },
            "vertical": { "type": "number", "exclusiveMinimum": 0, "maximum": 0.95, "default": 0.70 }
          }
        }
      }
    },
    "profiles": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "name", "color"],
        "additionalProperties": false,
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "name": { "type": "string", "minLength": 1 },
          "color": { "type": "string", "pattern": "^#[0-9A-F]{6}$" }
        }
      }
    },
    "slots": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "url", "profileId", "label", "keepAlive", "notifications"],
        "additionalProperties": false,
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "url": { "type": "string", "format": "uri", "pattern": "^https?://" },
          "profileId": { "type": "string", "format": "uuid" },
          "label": { "type": ["string", "null"] },
          "keepAlive": { "type": "boolean", "default": true },
          "notifications": { "type": "boolean", "default": true }
        }
      }
    }
  }
}
```

Example (first-run preset):

```json
{
  "schemaVersion": 1,
  "general": {
    "hideOnFocusLoss": true,
    "openAtLogin": false,
    "panelDepth": { "horizontal": 0.45, "vertical": 0.7 },
    "panelEdge": "right"
  },
  "profiles": [
    { "color": "#007AFF", "id": "6F1C...", "name": "Default" }
  ],
  "slots": [
    { "id": "A1...", "keepAlive": true, "label": null, "notifications": true, "profileId": "6F1C...", "url": "https://mail.google.com/" },
    { "id": "B2...", "keepAlive": false, "label": null, "notifications": true, "profileId": "6F1C...", "url": "https://calendar.google.com/" },
    { "id": "C3...", "keepAlive": true, "label": null, "notifications": true, "profileId": "6F1C...", "url": "https://chat.google.com/" }
  ]
}
```

### 3.4 Profile sessions

- Each Profile has one `WKWebsiteDataStore(forIdentifier: profile.id)`, shared by all its Slots and their Child windows. It persists on disk across restarts.
- Slots of different Profiles never share a store. Every webview of a Profile uses that store and no other.
- Deleting a Profile: close its Slots and Child windows, remove its notifications, then call `WKWebsiteDataStore.remove(forIdentifier:)`. If removal fails (pages or the network process still attached), add the UUID to `PendingStoreDeletions` and retry at the next launch before any webview is created. On success, remove it from the list.

## 4. Panel and Rail

Sources: [Panel behaviour](https://github.com/mogui/slotbar/issues/9), [Panel mechanics on macOS](https://github.com/mogui/slotbar/issues/7), [Keyboard input in a non-activating Panel](https://github.com/mogui/slotbar/issues/15)

### 4.1 Window

- `PanelWindow` is an `NSPanel` subclass: style `.nonactivatingPanel` with `.titled` removed, `canBecomeKey` returns `true`, `canBecomeMain` returns `false`.
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`. Together with `LSUIElement = true` this lets the Panel float over full-screen apps.
- Level `.popUpMenu` while sliding, `.floating` once shown.
- `hidesOnDeactivate = false`. At launch the Panel is hidden.
- Content: the Rail on the outer side (next to the screen edge) and the active Slot's webview filling the rest.

### 4.2 Placement

- Screen: the screen under the pointer at show time. The Panel stays on it until hidden.
- Space: the active Space (`canJoinAllSpaces`). It follows Space switches while shown.
- Frame: the full edge length of `screen.visibleFrame` on the chosen edge. The menu bar and Dock are never covered; when the Dock shares the edge, the Panel slides from the Dock's inner edge. Dock settings are untouched. Over full-screen apps, whatever `visibleFrame` reports is used.
- Display change (`NSApplication.didChangeScreenParametersNotification`): re-apply `collectionBehavior`, and hide the Panel if its screen is gone.
- Edge change in Settings applies at the next show and keeps the stored depth.

### 4.3 Size

- Depth (width for left/right, height for top/bottom) = `panelDepth.horizontal` or `panelDepth.vertical` times the screen's visible frame dimension, clamped to min 480 pt and max 95%.
- Resized only by dragging the inner border (a 6 pt tracking area with the matching resize cursor). The new fraction is written to `panelDepth` when the drag ends and is reused on every screen.

### 4.4 Rail

- An always-visible ~44 pt strip on the Panel's outer side: vertical for left/right edges, horizontal for top/bottom.
- One icon per Slot in list order, then a gear button at the end that opens Settings in the Panel; the gear is highlighted while Settings is shown.
- Each icon: the Slot's favicon (a gray globe while there is none), a Profile-color bar along its left side, and the unread badge for that Slot alone (section 8.4). The active Slot is highlighted.
- Tooltip: the Slot label, plus `Cmd+N` for the first nine Slots.
- Click: makes that Slot active (loading it if Unloaded).
- Right-click menu: Go home, Open current page in browser, Reload, separator, Notifications (check item bound to the Slot's `notifications` field, saved immediately).
- **Unloaded** Slots look the same as loaded ones (last favicon, no badge). The crash placeholder (section 6.4) is the only lifecycle UI.
- Favicon source: `favicon.js` (document start, main frame) reports the best `link[rel~="icon"]` URL; if none, `/favicon.ico` on the Home host. The image is fetched through the Slot's data store, scaled to 64x64 px, and cached to `favicons/<slot-id>.png`. It is refreshed when the icon link changes, except for Slots whose Home host is `chat.google.com`: they keep the first icon seen, because Chat swaps dot / no-dot favicon variants that feed only the Unread state. A Slot with no cached icon shows SF Symbol `globe` tinted with the Profile color. A Slot's cache file is deleted with the Slot and when its URL or Profile changes.
- With no Slots, the Panel shows only the Rail gear and a centered empty state "No Slots" with an "Open Settings" button that opens Settings.

### 4.5 Show, hide, toggle

- Toggle (global hotkey and status icon left-click) has three states:
  - Hidden: show and make key.
  - Shown but not key: make key, do not hide.
  - Panel or a Child window is key: hide.
- The status icon click records Panel visibility at mouse-down, so a click never hides and re-shows (the resign-key caused by the click itself is ignored).
- Show makes the last active Slot visible. It is held in memory; the first show after launch, or a show after the active Slot was deleted, uses Slot 1.
- A notification click and a routed link use the same show path, with a given target Slot.
- Hide: order out the Panel and its Child windows, then reactivate the previously frontmost app.
- Animation: 0.2 s slide from just outside the visible frame on the chosen edge (ease-out on show, ease-in on hide), via `NSAnimationContext` and `window.animator().setFrame`. A hide during a slide reverses from the current position. With Reduce motion on (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`), a ~0.15 s fade replaces the slide. No setting.
- Auto-hide ("Hide when Slotbar loses focus", on by default): when any Slotbar window resigns key and the new key window is not a Slotbar window, hide. Sheets, open/save panels, JS dialogs and Child windows therefore never hide it.
- Auto-hide off: the Panel stays `.floating` above other apps until toggled away. Clicking another app gives that app key and leaves the Panel on top.

### 4.6 Status item

- `NSStatusItem` with the template icon image, plus the unread badge as the button title (section 8.4).
- Left-click: toggle (section 4.5).
- Right-click or Ctrl-click menu: a "Hotkey unavailable" line when registration failed, Settings... (`Cmd+,`), About Slotbar, Quit Slotbar.
- Show in Dock on: activation policy `.regular`, so Slotbar has a Dock icon and is in the Cmd-Tab switcher. Activating the app (Cmd-Tab, Dock click) shows the Panel. Off: `.accessory`. Applied live.
- About opens the standard About panel (`orderFrontStandardAboutPanel`) with version and build and a credits line linking to `https://github.com/mogui/slotbar/releases`.

### 4.7 Child windows

Sources: [Panel behaviour](https://github.com/mogui/slotbar/issues/9), [Link routing rules](https://github.com/mogui/slotbar/issues/11), [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14)

- Created for popups that stay in the app (section 7.3): native `NSWindow`, titled, resizable, closable, miniaturizable, holding a `WKWebView` built from the configuration WebKit passes to `createWebViewWith`, so it shares the Slot's data store and has a real `window.opener`.
- Size from the `window.open` features (default 800x700 pt), clamped to the visible frame. Opens on the Panel's screen, centered in the area the Panel does not cover, and becomes key.
- `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`.
- Orders out with the Panel and comes back in place on show. A hide never closes it. A minimized Child window stays minimized and still counts as shown for the lifecycle.
- Title: `<page title> - <Profile name>`.
- Closed when its Slot is unloaded, crashes or is deleted, and when the page calls `window.close()`. `Cmd+W` closes it.
- Its notifications belong to the owning Slot. Its own page crash closes only that window and does not count toward the Slot's crash cap.

## 5. Slots and Profiles

Sources: [Settings data model and UI](https://github.com/mogui/slotbar/issues/10), [Persistent session isolation per Profile](https://github.com/mogui/slotbar/issues/3)

- A Slot is a starting URL + Profile. There is no service catalog. Google-specific knowledge lives outside the model: the first-run preset (section 11), the sign-in host list (section 7.2) and the host-keyed unread adapters (section 8.4).
- A Profile is shared by all Slots of the same Google account: one login per Profile.
- Deleting a Profile cascades to its Slots, their notifications, favicon caches and the session store, after a confirmation that lists the Slots (section 3.4).
- Deleting a Slot closes its webview and Child windows, removes its delivered notifications and deletes its favicon cache.

## 6. Slot lifecycle

Sources: [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14), [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13)

### 6.1 States

| State | Meaning |
|---|---|
| Unloaded | No webview. Settings and (until quit) the reopen URL are kept. Initial state of every non-keep-alive Slot. |
| Loaded, shown | Its webview is in the Panel and the Panel is on screen, or it has at least one open Child window (minimized included). |
| Loaded, hidden | Loaded but not shown. Non-keep-alive Slots run a grace timer in this state. |
| Crash placeholder | Auto-reload stopped after the crash cap. A native view with a "Reload" button replaces the webview. |

### 6.2 Rules

- Launch: every kept-alive Slot loads in the background at its starting URL, in list order, with no staggering. Others load on first open.
- **Keep-alive** Slots are never unloaded by Slotbar.
- Non-keep-alive Slot becomes hidden (Slot switch or Panel hide): start a fixed 5-minute grace timer (a code constant, no setting). Showing it again cancels the timer. When it fires, unload. A Slot with an open Child window counts as shown; closing its last Child window starts the full grace timer.
- Memory pressure: `DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])`. On either event, unload at once every hidden non-keep-alive Slot still in its grace period. Slots with open Child windows are skipped.
- Reopen URL: the last main-frame URL if its host is the Home host (sign-in hosts such as `accounts.google.com` count as foreign), else the starting URL. Kept in memory only; a relaunch opens starting URLs.
- A routed link into an Unloaded Slot loads it directly at the routed URL and shows it. A loaded target navigates in place.
- Keep-alive toggled in Settings: off starts the grace timer if the Slot is hidden; on loads the Slot immediately.
- `inactiveSchedulingPolicy` stays at its default. Hidden kept-alive webviews deliver network-driven notifications and title changes on time.

### 6.3 Unload

- Close the Slot's Child windows, remove the webview from its superview, and release it so its page process ends.
- Drop the Slot's Unread state contribution (section 8.4). Delivered notifications stay in Notification Center.
- Keep the cached favicon and the reopen URL.

### 6.4 Crashes

- `webViewWebContentProcessDidTerminate`:
  - Kept-alive or shown Slot: close its Child windows and reload right away at the reopen URL.
  - Hidden non-keep-alive Slot: mark it Unloaded; it reloads on open.
- Three terminations of one Slot within 10 minutes stop auto-reload and show the crash placeholder. Clicking "Reload" resets the counter and reloads.
- A Slot in the crash placeholder contributes its last Unread state as "count unknown".

## 7. Link routing

Sources: [Link routing rules](https://github.com/mogui/slotbar/issues/11), [Google login inside an embedded webview](https://github.com/mogui/slotbar/issues/4)

### 7.1 Main-frame navigations

Decided once per navigation, in `decidePolicyFor navigationAction`, on its first request. The initial load of the starting URL, the reopen URL and a routed URL are never routed.

Only clicked links (`navigationType == .linkActivated`) are routed. Form submissions and script navigations stay in the Slot.

| Case | Route |
|---|---|
| Host equals the Home host | Stay in the Slot. |
| Host equals the Home host of another Slot of the same Profile (first in list order) | Show that Slot and load the URL there (section 6.2). Never a Slot of another Profile. |
| Host equals the current page's host | Stay in the Slot. |
| Any other host, subdomains of the same domain included | Default browser (`NSWorkspace.shared.open`). |
| Cmd-click or middle-click (`modifierFlags.contains(.command)` or `buttonNumber == 4`) | The opposite of the default: a link that would stay (or go to another Slot) opens in the default browser; a link that would go to the browser loads in the Slot. |
| Link context menu | **Open Link in Slotbar** loads the link in the Slot (or Child window); **Open Link in Browser** opens it in the default browser. Always offered, also in Sign-in mode. |
| Form submissions, script navigations | Stay in the Slot. |
| Server redirects (3xx) | Never routed. |
| Sub-frames (iframes) | Never routed; load in place. |
| `accounts.google.<any TLD>`, `accounts.youtube.com` | Enter **Sign-in mode** (section 7.2). |
| `google.<any TLD>/url?q=` or `?url=` wrappers | Unwrap and route the real target. If it is missing or not absolute `http`/`https`, open the wrapper as is in the default browser. |
| Non-`http(s)` schemes (`mailto:`, `tel:`, `zoommtg:` ...) | `NSWorkspace.shared.open` (macOS default handler). `about:`, `blob:`, `data:` and `javascript:` from the page itself load in place. |

The Google host lists are hardcoded. There are no routing settings.

### 7.2 Sign-in mode

- Entered when a main-frame navigation targets a sign-in host.
- While active, every main-frame navigation and every popup stays in the Slot (any third-party IdP host included).
- Ends when the main frame commits a navigation on the Home host, or 10 minutes after entry.

### 7.3 Popups

- `window.open` and `target=_blank` (`createWebViewWith`): the target is routed by the rules above. A `window.open` without width and height counts as a clicked link.
- It stays when the route is "stay in the Slot" (Home host or the opener page's host, Cmd-click on another host, or a `window.open` from script with a width or height), when the URL is `about:blank` or empty and the opener is on the Home host, or when the Slot is in Sign-in mode. It opens as a **Child window** (section 4.7).
- Otherwise it opens in the default browser and `nil` is returned (no window).
- Popups without a user gesture follow the WebKit default (blocked).

### 7.4 Downloads and uploads

Sources: [Link routing rules](https://github.com/mogui/slotbar/issues/11)

- A navigation response with `Content-Disposition: attachment` or a MIME type the webview cannot show (`canShowMIMEType == false`) becomes a `WKDownload` (`decidePolicyFor navigationResponse` returns `.download`). `<a download>` actions too.
- Destination: `~/Downloads/<suggested filename>`. On a name clash, append ` (1)`, ` (2)` ... before the extension.
- On finish, post the distributed notification `com.apple.DownloadFileFinished` with the file path as object, so the Dock Downloads stack bounces. No in-app UI and no system notification. A failed or cancelled download is logged and its partial file is deleted.
- Uploads: `runOpenPanelWith` shows an `NSOpenPanel` as a sheet on the owning window, honoring `allowsMultipleSelection` and `allowsDirectories`.

### 7.5 Per-Slot actions

- Go home: load the starting URL in the Slot.
- Open current page in browser: `NSWorkspace.shared.open` with the Slot's current main-frame URL.
- Reload: `webView.reload()`.
- Reached from the Rail right-click menu and, for the active Slot, from the Panel shortcuts (section 9).

### 7.6 Other WKUIDelegate behaviour

- JS `alert`, `confirm`, `prompt`: an `NSAlert` sheet on the owning window (Panel or Child window).
- Camera, microphone and screen capture requests: denied (`requestMediaCapturePermissionFor` returns `.deny`). Info.plist carries no camera or microphone usage strings.
- Geolocation is never granted.

## 8. Notifications and unread badge

Sources: [Notification behaviour](https://github.com/mogui/slotbar/issues/12), [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13), [Web Notifications in WKWebView on macOS](https://github.com/mogui/slotbar/issues/2), [Source of unread counts for Gmail and Chat](https://github.com/mogui/slotbar/issues/6)

### 8.1 Shim

- `notification-shim.js` is a `WKUserScript` at document start, in all frames (`forMainFrameOnly: false`), in the `.page` content world.
- It replaces `window.Notification` with a class whose static `permission` is `"granted"` and whose `requestPermission()` resolves `"granted"` (callback form too). It overrides `ServiceWorkerRegistration.prototype.showNotification` so it resolves after posting through the same bridge.
- Each notification is sent through one `WKScriptMessageHandlerWithReply` named `slotbarNotify` with `{ op: "show", title, body, tag, silent, pageId }` and gets a native id back. `notification.close()` sends `{ op: "close", id }`. `onclick` is held in the page, keyed by the native id.
- The native side reads the frame origin from `WKScriptMessage.frameInfo.securityOrigin` and the Slot from the webview that owns the handler (a Child window maps to its owning Slot).
- Notifications raised inside a service worker cannot be shimmed. Web Push does not exist in WKWebView, so a Slot notifies only while it is loaded.

### 8.2 Delivery

- Authorization: `requestAuthorization(options: [.alert, .sound])` once at first launch. If it is denied, Settings > General shows "Notifications are off in System Settings" with an Open button (`x-apple.systempreferences:com.apple.Notifications-Settings.extension`).
- Drop the notification when the Slot's `notifications` is off. The page still sees "granted", and the badge is unaffected.
- De-dup, cross-Slot origin rule: drop a notification when its frame origin host differs from the delivering Slot's Home host and equals the Home host of another currently loaded Slot of the same Profile. A muted but loaded Slot still suppresses the copy.
- Request identifier: `<Profile UUID>|<origin host>|<tag>` when the page passes a `tag` (same id replaces the earlier notification), else a random UUID.
- Content: title = page title argument, subtitle = Slot label, body = page body, `threadIdentifier` = Slot id, `userInfo` = Slot id + page instance id + native id. The page `icon` is ignored. Sound `.default` unless `silent: true`. `interruptionLevel = .active`.
- Focus, Do Not Disturb and sound settings are governed by macOS (System Settings > Notifications > Slotbar). No in-app pause or sound setting.
- Foreground: `willPresent` returns no options (neither shown nor stored) when the Panel is on screen and showing the originating Slot; otherwise `[.banner, .list, .sound]` (without `.sound` when silent).
- Page `close()` removes the delivered notification. Deleting a Slot removes its delivered notifications; unloading does not.

### 8.3 Click

- `didReceive response`: show the Panel on the originating Slot through the normal show path (an Unloaded Slot loads at its reopen URL). Child windows are not brought forward.
- If the same page instance is still alive, call the page's `onclick` for that native id via `evaluateJavaScript`.
- Deep link: when no page handler takes the click (no `onclick` and no `click` listener, as with notifications posted through `registration.showNotification`) or the page instance is gone, a link derived from the notification's `data` opens in the Slot. While the originating webview is alive and shows the link's host, the link opens in-page (`history.pushState` plus a `popstate` event), with no reload; otherwise it loads through the routed-link path. `chat.google.com`: the space or DM id in `data` opens `https://chat.google.com/app/chat/<id>`. Other hosts have no deep link.

### 8.4 Unread state and badge

Per loaded Slot, the **Unread state** is a count N, "count unknown" (dot), or none. A failing source keeps the last known value and never writes 0.

Host-keyed adapters (outside the Slot model, chosen by Home host):

| Home host | Source |
|---|---|
| `mail.google.com` | `unread-gmail.js`: DOM Inbox count (the count next to `a[href*="#inbox"]`), observed with a `MutationObserver`. A count of 0 is valid. Only while the selector is not found: in-page same-origin `fetch('/mail/feed/atom')`, read `<fullcount>` immediately, then every 60 s; stop when the DOM reads again. Log each switch. Never for Unloaded Slots. If both fail, keep the last value as "count unknown". |
| `chat.google.com` | `unread-chat.js`: favicon dot only (`link[rel~="icon"]` href contains `_dot_` = unread, `_no_dot_` = none). No DOM count. |
| Any other host | `unread-title.js`: a leading `(N)` in `document.title` (via the webview's `title` KVO), else no contribution. Calendar therefore contributes nothing. |

Aggregation (`BadgeAggregator`):
- Group loaded Slots by (Profile, Home host) and take the max count in each group. Sum the groups.
- Add the dot when any Slot is "count unknown".
- Unloaded Slots contribute nothing. A Slot in the crash placeholder contributes its last state as "count unknown".
- Gmail's Inbox count excludes Chat, so there is no Gmail/Chat double count.

Rendering:
- Status item: the button title in monospaced digits next to the template icon: `1` ... `99`, then `99+`. A dot (`U+25CF`) alone for "count unknown" only, `N` plus the dot when both apply, nothing when there are no unread items. It follows the menu bar appearance with no custom colors.
- Rail: the same format for each Slot's own state (no cross-Slot de-dup), as a small filled capsule over the favicon.

Logging: `os.Logger(subsystem: "io.github.mogui.slotbar", category: <module>)` for adapter switches, signal disagreements, routing decisions in Debug, crashes, store deletions and download failures.

## 9. Keyboard

Sources: [Keyboard input in a non-activating Panel](https://github.com/mogui/slotbar/issues/15), [Panel behaviour](https://github.com/mogui/slotbar/issues/9)

- Web text input, dead keys and Gmail single-key shortcuts work in the key non-activating Panel with no extra code.
- `PanelWindow.performKeyEquivalent(with:)` handles these and consumes them before the webview, matching modifiers as `event.modifierFlags.intersection([.command, .shift, .option, .control])`:

| Keys | Action |
|---|---|
| `Cmd+1` ... `Cmd+9` (exactly `.command`) | Make Slot N active (no-op if there is no Slot N). |
| `Cmd+Shift+H` | Go home (active Slot). |
| `Cmd+Shift+O` | Open current page in browser (active Slot). |
| `Cmd+R` | Reload (active Slot). |
| `Cmd+W` | Hide the Panel (closes nothing). |

- In a Child window, `Cmd+W` closes that window. Other keys go to the page.
- Esc is not bound; pages own it.
- Main menu (`NSApp.mainMenu`, visible only with Show in Dock): an App menu with About Slotbar, Settings... (`Cmd+,`), Quit Slotbar (`Cmd+Q`), and an Edit menu with Undo (`Cmd+Z`), Redo (`Cmd+Shift+Z`), Cut, Copy, Paste, Select All, using the standard first-responder selectors. Without it, `Cmd+A/C/V/Z` do nothing in web fields.
- Global hotkey: KeyboardShortcuts name `togglePanel`, default `Ctrl+Option+S`, recordable in Settings > General. No per-Slot hotkeys. When registration fails, Settings shows an inline warning and the status menu shows "Hotkey unavailable"; the icon click still works.

## 10. Settings UI

Sources: [Settings data model and UI](https://github.com/mogui/slotbar/issues/10), [Panel behaviour](https://github.com/mogui/slotbar/issues/9), [Notification behaviour](https://github.com/mogui/slotbar/issues/12), [Build and release pipeline](https://github.com/mogui/slotbar/issues/16)

- Settings is shown inside the Panel, in the Slot area in place of the active Slot: one scrolling page, a grouped SwiftUI `Form` in a centered column of at most 640 pt, with the sections General, Profiles, Slots. Opened by `Cmd+,`, the status menu, the Rail gear and the empty-state button; opening it shows the Panel. Clicking a Slot icon or a `Cmd+1...9` shortcut returns to that Slot; the next show of the Panel shows a Slot. While Settings is shown, no Slot counts as on screen.
- Every edit is saved immediately to `settings.json` and applied live. A change made from the Rail menu shows live in Settings.

### 10.1 General

| Row | Behaviour |
|---|---|
| Global hotkey | `KeyboardShortcuts.Recorder` for `togglePanel`. Inline warning when registration failed. |
| Panel edge | Segmented control Left / Right / Top / Bottom, default Right. Applies at the next show and keeps the depth. |
| Hide when Slotbar loses focus | Switch, on. |
| Show in Dock | Switch, off, with the hint "Switch to Slotbar with Cmd-Tab". Section 4.6. |
| Open at login | Switch, off. On calls `SMAppService.mainApp.register()`, off calls `unregister()`. If registration fails, an inline error appears and the switch stays off. |
| Notifications are off in System Settings | Shown only when authorization is denied, with an Open button. |

### 10.2 Profiles

- One row per Profile: color swatch, name (editable inline), trash button. A "+" button in the section header adds a Profile.
- Color: a fixed 8-color palette shown as swatches: blue `#007AFF`, purple `#AF52DE`, pink `#FF2D55`, red `#FF3B30`, orange `#FF9500`, yellow `#FFCC00`, green `#34C759`, graphite `#8E8E93`. A new Profile gets the first unused color; when all 8 are used, the least-used color, first in palette order on ties. Its default name is "Profile N".
- The trash button asks for confirmation listing the Slots that will be deleted with it, then cascades (section 5). Deleting the last Profile is allowed.

### 10.3 Slots

- One row per Slot in Slot order: icon; Label (editable inline; clearing it sets `label: null`, so the auto-label is set again at the next load); URL below it; then Profile (popup), Keep-alive (checkbox), Notifications (checkbox). A menu button on each row offers Move Up, Move Down and Delete.
- A "+" button in the section header opens a sheet with URL (required) and Profile (popup, default the first Profile). The URL must parse as absolute `http` or `https`; a bare host gets `https://` prepended. The new Slot is appended with Keep-alive on, Notifications on and `label: null`. "+" is disabled and the section shows "Add a Profile first" when there are no Profiles.
- Editing the URL or the Profile keeps the label and position, closes the Slot's Child windows, clears its reopen URL and deletes its cached favicon. A URL change resets the Home host, and routing uses the new one immediately. A loaded Slot reloads at the new URL (a Profile change recreates its webview on the new Profile's store). An Unloaded Slot is only updated in the model and loads the new URL on next open.
- Delete removes the Slot with no confirmation (section 5).

## 11. First-run preset

Sources: [Settings data model and UI](https://github.com/mogui/slotbar/issues/10), [Link routing rules](https://github.com/mogui/slotbar/issues/11), [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14)

Written when `settings.json` does not exist (or replaced a corrupt one):

| Item | Value |
|---|---|
| Profile | "Default", blue `#007AFF`, new UUID |
| Slot 1 | `https://mail.google.com/`, Keep-alive on, Notifications on |
| Slot 2 | `https://calendar.google.com/`, Keep-alive off, Notifications on |
| Slot 3 | `https://chat.google.com/`, Keep-alive on, Notifications on |
| General | edge right, hide on focus loss on, open at login off, depth 0.45 / 0.70 |

First launch also requests notification authorization (section 8.2). The Panel stays hidden; the user opens it with the hotkey or the status icon and signs in inside the Gmail Slot.

## 12. Build and release

Sources: [Build and release pipeline](https://github.com/mogui/slotbar/issues/16), [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13)

### 12.1 Package and toolchain

- `Package.swift`: `swift-tools-version: 6.0`, Swift 6 language mode, `platforms: [.macOS(.v14)]`, one executable target `Slotbar`, the test target `SlotbarTests` (section 2), KeyboardShortcuts as the only dependency. CI runs no tests.
- Toolchain: CI pins Xcode 26.3 via `DEVELOPER_DIR` (the newest on the `macos-15-intel` image; its default Xcode 16.4 fails on the Swift 6 concurrency checks).
- Architectures: universal arm64 + x86_64: one `swift build --build-system swiftbuild -c release --arch <arch>` per arch, joined with `lipo -create` (a multi-arch `swift build` switches to the Xcode build system, which fails with Swift 6 on the CI runner image). x86_64 is dropped the first time the runner's Xcode refuses it. Intel is best effort.

### 12.2 `scripts/build-app.sh [debug|release]`

1. `swift build --build-system swiftbuild` in the given configuration (for release, once per arch, then `lipo -create`). Swift Build looks up dependency resource bundles in `Contents/Resources`; the native build system looks next to the `.app` and its binaries are rejected by a gate.
2. Assemble `build/Slotbar.app/Contents/{MacOS/Slotbar, Resources/, Info.plist}`, copying the files from `Resources/` and the SwiftPM resource bundles (`*.bundle`, KeyboardShortcuts) from the bin path.
3. Fill the `Info.plist` version placeholders: `CFBundleShortVersionString` from the `VERSION` env var (default `0.0.0-dev`), `CFBundleVersion` from `BUILD_NUMBER` (default `0`).
4. `codesign --force --deep -s - build/Slotbar.app`.
5. `codesign --verify --strict build/Slotbar.app` as a hard gate (non-zero exit fails the script).

`debug` builds keep `isInspectable` on via `DEBUG`.

### 12.3 Identity (`Resources/Info.plist`)

| Key | Value |
|---|---|
| `CFBundleIdentifier` | `io.github.mogui.slotbar` (frozen from `v0.1.0`) |
| `CFBundleName`, `CFBundleDisplayName` | `Slotbar` |
| `CFBundleExecutable` | `Slotbar` |
| `CFBundleIconFile` | `AppIcon` |
| `LSUIElement` | `true` |
| `LSMinimumSystemVersion` | `14.0` |
| `NSHumanReadableCopyright` | credits line text |

Signing is ad-hoc only: a sealed bundle signature is required to post notifications (a linker-only signature fails). No hardened runtime, no entitlements, no App Sandbox.

### 12.4 Release workflow

- `.github/workflows/release.yml`, triggered only on `v*` tag pushes, on the `macos-15-intel` runner (the arm64 queue is often out of capacity); it builds the universal app all the same. The YAML only calls scripts.
- Steps (`scripts/release.sh vX.Y.Z`): `VERSION=${tag#v} BUILD_NUMBER=$GITHUB_RUN_NUMBER scripts/build-app.sh release`; a DMG `build/Slotbar-X.Y.Z.dmg` (`hdiutil create -format UDZO`, volume "Slotbar X.Y.Z") holding `Slotbar.app` and an `Applications` symlink; `shasum -a 256`; then `gh release create vX.Y.Z Slotbar-X.Y.Z.dmg --title "Slotbar X.Y.Z" --generate-notes` with notes giving the install steps (drag to Applications, `xattr -dr com.apple.quarantine`) and the SHA-256. `PUBLISH=0` stops after the DMG.
- Versioning: SemVer tags from `v0.1.0`. Pre-1.0: minor = features, patch = fixes. Local builds are never uploaded.
- No update checks. Upgrades are manual downloads from GitHub Releases.

### 12.5 Location guard and Open at login

- At launch, if `Bundle.main.bundlePath` contains `/AppTranslocation/` or is outside `/Applications/` and `~/Applications/`, show one `NSAlert` "Move Slotbar to Applications" (informative text: notifications need it) with a single OK. The app continues. It is shown at every launch while the condition holds.
- At launch, if `openAtLogin` is `true` and `SMAppService.mainApp.status != .enabled`, call `register()` again. On failure, set `openAtLogin` to `false` and show the inline error in Settings > General.

## 13. README content

Sources: [Choose the stack](https://github.com/mogui/slotbar/issues/8), [Build and release pipeline](https://github.com/mogui/slotbar/issues/16), [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14), [Notification behaviour](https://github.com/mogui/slotbar/issues/12), [Google login inside an embedded webview](https://github.com/mogui/slotbar/issues/4)

`README.md` opens with the app icon, a one-line description and badges (latest release, macOS 14+, Swift 6), then a **Features** list, then these sections:

1. **What it is**: menu bar app, Panel from a screen edge, one Profile per Google account, `Ctrl+Option+S`, `Cmd+1..9`. Requires macOS 14+.
2. **Install**: download `Slotbar-X.Y.Z.dmg` from Releases, check the SHA-256, open it and drag `Slotbar.app` to `/Applications`, run `xattr -dr com.apple.quarantine /Applications/Slotbar.app`, open it. Alternative: open it once, then System Settings > Privacy & Security > "Open Anyway" (macOS 15+ has no Control-click Open). The app must live in `/Applications` or `~/Applications` for notifications.
3. **First run**: the preset (Gmail, Calendar, Chat in Profile "Default"), allow notifications, sign in. Tip: "If you have a Chat Slot, turn off Chat in Gmail (Settings > Chat and Meet > Chat: Off)" to avoid loading Chat twice.
4. **Signing in**: use password + 2FA; on a passkey or security-key prompt choose "Try another way". Advanced Protection and security-key-enforced Workspace accounts are not supported as Profiles. Slotbar presents a Firefox user agent; override it with `defaults write io.github.mogui.slotbar UserAgent "<string>"` and relaunch (`defaults delete io.github.mogui.slotbar UserAgent` to reset).
5. **Usage**: Rail, right-click actions, shortcuts table (section 9), Settings in the Panel (General, Profiles, Slots; Keep-alive and Notifications per Slot).
6. **Upgrade**: quit, drag the new app from the DMG onto `/Applications`, strip quarantine again, open. macOS may show a "Login item added" banner after each upgrade when Open at login is on.
7. **Build from source**: `scripts/build-app.sh release`, output in `build/Slotbar.app`; `swift test` runs the unit tests. Releasing: push a `vX.Y.Z` tag; `PUBLISH=0 scripts/release.sh vX.Y.Z` builds the DMG locally.
8. **Limitations**: unsigned (ad-hoc, not notarized) app; no passkeys; opening a Chat conversation from a notification reloads the Chat Slot; notifications only from loaded Slots; calls and huddles (Meet, Chat): use the browser; Google may block embedded sign-in at any time.

## 14. Verification on first build

Residuals that need a real Google login or a GUI session. Each lists the assumption the spec takes and the fallback.

| # | Check | Assumption in this spec | If it fails | Source |
|---|---|---|---|---|
| 1 | Google sign-in (personal and Workspace) succeeds with the Firefox UA in a Slot. | Works (google-chat-tauri evidence). | Try a Safari UA via the `UserAgent` override; if it works, make it the constant. | [Choose the stack](https://github.com/mogui/slotbar/issues/8) |
| 2 | Login survives an app restart in a `WKWebsiteDataStore(forIdentifier:)` store. | Google auth cookies are persistent (`Max-Age`). | Blocker: report it. | [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13) |
| 3 | The sign-in redirect chain passes through `accounts.google.*` / `accounts.youtube.com` and returns to the Home host within 10 minutes, Workspace SSO IdPs included. | Yes. | Add the observed host to the hardcoded sign-in list. | [Link routing rules](https://github.com/mogui/slotbar/issues/11) |
| 4 | Gmail attachments download from `*.googleusercontent.com` with attachment disposition into `~/Downloads`. | Yes. | Adjust the download trigger in `decidePolicyFor navigationResponse`. | [Link routing rules](https://github.com/mogui/slotbar/issues/11) |
| 5 | Which path Gmail and Chat use to notify (`new Notification()` or page-called `registration.showNotification()`), and that both arrive through the shim. | One of the two shimmed paths. | If Chat notifies only from inside the service worker, Chat notifications cannot be delivered: document it in Limitations. | [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13) |
| 6 | Frame origin of Chat inside Gmail is `https://chat.google.com`, and Chat raises duplicates in Gmail and the Chat Slot. | Yes; the origin rule drops Gmail's copy. | The rule is generic; only confirm no Chat notification is lost when the Chat Slot is Unloaded. | [Notification behaviour](https://github.com/mogui/slotbar/issues/12) |
| 7 | Whether Gmail/Chat set `tag`, and whether Chat stops notifying when it sees an open Chat Slot (idle detection). | Untagged duplicates are handled by the origin rule. | None needed. | [Notification behaviour](https://github.com/mogui/slotbar/issues/12) |
| 8 | Gmail DOM Inbox count and Chat favicon dot stay fresh while the Slot is hidden for 10+ minutes. | Fresh (hidden pages process network events in < 130 ms). | None planned; report. | [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13) |
| 9 | Gmail Atom feed fallback answers on a consumer `@gmail.com` account. | Best effort. | Leave as is; the state falls back to "count unknown". | [Source of unread counts for Gmail and Chat](https://github.com/mogui/slotbar/issues/6) |
| 10 | Gmail selector `a[href*="#inbox"]` count and Chat `_dot_` / `_no_dot_` favicon names match current Google UIs. | Yes. | Update the adapter scripts. | [Source of unread counts for Gmail and Chat](https://github.com/mogui/slotbar/issues/6) |
| 11 | Gmail setting path "Settings > Chat and Meet > Chat: Off" for the README tip. | Exists. | Fix the README wording. | [Lifecycle of Slots without keep-alive](https://github.com/mogui/slotbar/issues/14) |
| 12 | Physical keystrokes reach the key non-activating Panel while another app is frontmost: typing, Gmail single keys, `Cmd+1..9`, `Cmd+A/C/V/Z`; also a CJK IME. | Yes (prior art: Ghostty quick terminal). | Report; the in-process matrix passed. | [Keyboard input in a non-activating Panel](https://github.com/mogui/slotbar/issues/15) |
| 13 | `Ctrl+Option+S` is free in the system symbolic hotkeys. | Free. | The recorder and the "Hotkey unavailable" warning cover it. | [Panel behaviour](https://github.com/mogui/slotbar/issues/9) |
| 14 | Panel slide from the Dock's inner edge, Child windows (`.floating` + `canJoinAllSpaces`) over full-screen apps, and the Reduce motion fade on real hardware. | Work as specified. | Fix in `PanelController` / `ChildWindowController`. | [Panel behaviour](https://github.com/mogui/slotbar/issues/9) |
| 15 | Full (non-provisional) notification authorization prompt appears at first launch and notifications post. | Yes (only provisional was measured). | Report. | [Live test: how Gmail and Chat raise notifications in a WKWebView](https://github.com/mogui/slotbar/issues/13) |
| 16 | Downloaded release zip, moved with Finder, opened via "Open Anyway": a notification posts. | Works once launched from `/Applications`. | README makes the `xattr` command mandatory. | [Build and release pipeline](https://github.com/mogui/slotbar/issues/16) |
| 17 | `SMAppService.mainApp.register()` works for the ad-hoc build in `/Applications`, and the launch self-heal after an upgrade. | Works. | Remove "Open at login" from Settings and document manual Login Items. | [Build and release pipeline](https://github.com/mogui/slotbar/issues/16) |
| 18 | KeyboardShortcuts resolves and builds universal under SwiftPM on the CI runner. | Yes. | Fix the package pin; the stack keeps KeyboardShortcuts. | [Build and release pipeline](https://github.com/mogui/slotbar/issues/16) |
| 19 | Behaviour on macOS 14 and 15. | Best effort. | Add OS-version branches only for reported bugs. | [Choose the stack](https://github.com/mogui/slotbar/issues/8) |
