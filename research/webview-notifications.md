# Web Notifications in WKWebView on macOS

Research for [#2](https://github.com/mogui/slotbar/issues/2). Researched 2026-11-02 against WebKit `main`, the macOS 27.0 SDK headers, and a test run on macOS 26.6.2.

## Answer

- **Out of the box, Web Notifications do not work in a third-party WKWebView.** `window.Notification` exists, but `Notification.requestPermission()` resolves to `"denied"` and nothing is ever shown. The public WebKit API has no notification permission delegate and no way to display notifications.
- **Web Push and service-worker push do not work either.** `PushManager` is undefined in a default WKWebView, and the only push plumbing is private SPI that only Safari uses.
- **A JS shim works and is proven in shipping open-source apps.** It replaces `window.Notification` from a `WKUserScript` and bridges through `WKScriptMessageHandler(WithReply)` to `UNUserNotificationCenter`. Multi (Swift, WKWebView) and Pake (Tauri/wry, WKWebView on macOS) both do this.
- **Limits of the shim:** a notification is only delivered while the Slot's page is loaded and running. That matches the Keep-alive design, but there is no push while the page is unloaded. Service-worker `showNotification` is not covered. Click routing has to be built by hand, both to the Slot and back into the page's `onclick`.

## Findings

### 1. Public API surface (verified)

- The public headers in the macOS 27.0 SDK (`WKUIDelegate.h`, `WKPreferences.h`, `WKWebsiteDataStore.h`, `WKWebViewConfiguration.h`) have no notification permission or display API. The only match for "notification" in `WKWebView.h` is about fullscreen state KVO. Source: local SDK `MacOSX27.0.sdk/System/Library/Frameworks/WebKit.framework/Headers/`.
- `WKUIDelegate` covers only media capture permission (camera/mic). It has no notification permission callback. Source: same headers.

### 2. What WebKit does internally (verified, WebKit `main`)

- The `Notification` interface is `EnabledBySetting=NotificationsEnabled` and `Exposed=(Window,DedicatedWorker,ServiceWorker)`. Source: [Notification.idl](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/Modules/notifications/Notification.idl).
- `NotificationsEnabled` defaults to `true` on everything except iOS-family platforms. `PushAPIEnabled` defaults to `false` (status `embedder`). `ServiceWorkersEnabled` defaults to `true` for WebKit. Source: [UnifiedWebPreferences.yaml](https://github.com/WebKit/WebKit/blob/main/Source/WTF/Scripts/Preferences/UnifiedWebPreferences.yaml).
- If the UI delegate does not implement the private `_webView:requestNotificationPermissionForSecurityOrigin:decisionHandler:`, the permission request is completed with `false`. Source: `UIDelegate::UIClient::decidePolicyForNotificationPermissionRequest` in [UIDelegate.mm](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/Cocoa/UIDelegate.mm).
- The relevant SPI is all underscore-prefixed or private:
  - `WKUIDelegatePrivate`: `_webView:requestNotificationPermissionForSecurityOrigin:decisionHandler:`, macOS 10.13.4+. Source: [WKUIDelegatePrivate.h](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKUIDelegatePrivate.h).
  - `WKPreferencesPrivate`: `_notificationsEnabled` (10.13.4), `_notificationEventEnabled` (13.3), `_pushAPIEnabled` (13.0). Source: [WKPreferencesPrivate.h](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKPreferencesPrivate.h).
  - `_WKWebsiteDataStoreDelegate`: `showNotification:`, `notificationPermissionsForWebsiteDataStore:`, `navigateToNotificationActionURL:`, `updatedAppBadge:`. Source: [_WKWebsiteDataStoreDelegate.h](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/_WKWebsiteDataStoreDelegate.h).
  - `WKWebsiteDataStorePrivate`: `_processPushMessage:`, `_processPersistentNotificationClick:`, `_getPendingPushMessages:` (macOS 13.0+). `_WKWebsiteDataStoreConfiguration.webPushMachServiceName` (13.0+) points to a `webpushd`-style daemon. Sources: [WKWebsiteDataStorePrivate.h](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStorePrivate.h), [_WKWebsiteDataStoreConfiguration.h](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/_WKWebsiteDataStoreConfiguration.h).
- WebKit's own announcement scopes Web Push to "Safari 16 on macOS Ventura" and says it "requires deep per-platform and per-application customization". It says nothing about WKWebView embedders. Source: [Meet Web Push](https://webkit.org/blog/12945/meet-web-push/).

### 3. Empirical test on macOS 26.6.2 (verified, scripts in `/tmp/wknotif-test`, not committed)

Plain `WKWebView` with a default `WKWebViewConfiguration`, page loaded with `baseURL https://example.com/`:

| Check | Result |
|---|---|
| `typeof Notification` | `"function"` |
| `Notification.permission` before | `"default"` |
| `await Notification.requestPermission()` | `"denied"` (no prompt) |
| `'serviceWorker' in navigator` | `true` |
| `typeof PushManager` | `"undefined"` |

Same setup, with the private `_webView:requestNotificationPermissionForSecurityOrigin:decisionHandler:` implemented and returning `true`:

| Check | Result |
|---|---|
| SPI invoked | yes |
| `requestPermission()` | `"granted"` |
| `new Notification(...)` events within 3 s | none (no `show`, no `error`) |

So the private permission hook is not enough on its own. Displaying a notification also needs a notification provider, which is only reachable through more private SPI. Inferred from the missing `show` event and the C-API `WKNotificationProvider`/`WKNotificationManager` in `Source/WebKit/UIProcess/API/C/`, not traced end to end.

### 4. The bridge used by real apps (verified from source)

**Multi** (`kofigumbs/multi`, Swift + WKWebView, commit `b59a415`, 2026-09-17):
- `Multi.app/Contents/Resources/notification.js` replaces `window.Notification` with a class:
  - `requestPermission()` calls `webkit.messageHandlers.notificationRequest.postMessage` and resolves to `granted` or `denied`.
  - The constructor builds a real `Notification` for option parsing, then posts `{title, tag, body, icon}` to `notificationShow`.
  - `close()` posts to `notificationClose`.
- `Sources/MultiRuntime/TabView.swift` injects the shim with `WKUserScript(..., injectionTime: .atDocumentStart, forMainFrameOnly: false)`:
  - `notificationRequest` maps to `UNUserNotificationCenter.requestAuthorization()`.
  - `notificationShow` maps to `UNMutableNotificationContent` with `userInfo = ["tab": index]`, then `add(UNNotificationRequest(identifier: tag, ..., trigger: nil))`.
  - `notificationClose` maps to `removeDeliveredNotifications(withIdentifiers:)`.
- `Sources/MultiSettings/ContentView.swift` registers the handlers with `addScriptMessageHandler(_:contentWorld: .page, name:)` (the reply variant, `WKScriptMessageHandlerWithReply`, macOS 11.0+ per SDK header).
- Click routing in `Sources/MultiRuntime/RuntimeDelegate.swift`: `UNUserNotificationCenterDelegate.didReceive` reads `userInfo["tab"]` and opens that tab's window. `willPresent` returns `.banner` only if `alwaysNotify` is set, otherwise it suppresses banners while the app is frontmost.
- Gap: it never fires the page's own `onclick`, so the web app does not navigate to the specific conversation.

**Pake** (`tw93/Pake`, Tauri/wry, which uses WKWebView on macOS, commit `c7606f5`, 2026-11-02):
- `src-tauri/src/inject/event.js` replaces `window.Notification` through `Object.defineProperty` synchronously at injection, so feature detection sees the polyfill. It reports `permission` as `"granted"`, assigns ids, honours `tag` replacement, and also shims `navigator.setAppBadge`/`clearAppBadge` for the Dock badge.
- `src-tauri/src/app/notification.rs` documents why page click routing breaks with a naive shim: "Slack never jumps to the conversation the notification came from". On macOS it delivers through `NSUserNotificationCenter` with a delegate and calls back into the page (`__pakeNotificationClick(id)`), which dispatches `click` on the right `Notification` object.
- It dedupes identical notifications raised by several windows of the same site within 1 s. That case also applies to Slotbar if two Slots share a service and Profile.

### 5. Limits of the shim approach

| Limit | Status |
|---|---|
| No delivery when the page is not loaded. No Web Push to wake it. | Verified (`PushManager` undefined, push is private SPI). Matches the Keep-alive concept: only kept-alive Slots can notify. |
| `ServiceWorkerRegistration.showNotification()` is not covered by a `window.Notification` shim. User scripts do not run inside service workers. | Inferred. Mitigation: also override `ServiceWorkerRegistration.prototype.showNotification` in the page world (it is callable from the page). Pushes handled inside the worker stay unreachable. |
| Shim must run in the `.page` content world at document start, in all frames (`forMainFrameOnly: false`), so it replaces the global before site scripts read it. | Verified as what Multi and Pake do. Whether Gmail/Chat raise notifications from subframes is not verified. |
| Click routing: the native side has to carry the Slot id in `userInfo` and call back into the page so the page's `onclick` runs. | Verified from Pake's notes and Multi's gap. |
| `UNUserNotificationCenter` authorization in an unsigned app. | Not verified from Apple docs. Developer reports say unsigned apps get "Notifications are not allowed for this application" and ad-hoc signing (`codesign -s -`) fixes it: [bitcoin-core-gui#112](https://mirror.b10c.me/bitcoin-core-gui/112/), [Apple forums 718777](https://developer.apple.com/forums/thread/718777). Apple Silicon requires at least ad-hoc signatures anyway. |
| Hidden or occluded WKWebViews may be throttled (timers, rendering), which could delay notification polling in kept-alive Slots. | Inferred, not tested. |
| Whether Gmail and Chat call `new Notification()` from the page or `registration.showNotification()` from a service worker, and whether they use Web Push in Safari. | Not verified. This needs a live test with a logged-in account and the shim logging calls. |

## Sources

- WebKit source, `main` branch (fetched 2026-11-02): `Notification.idl`, `UnifiedWebPreferences.yaml`, `UIDelegate.mm`, `WKUIDelegatePrivate.h`, `WKPreferencesPrivate.h`, `_WKWebsiteDataStoreDelegate.h`, `WKWebsiteDataStorePrivate.h`, `_WKWebsiteDataStoreConfiguration.h`, `_WKNotificationData.h` (links inline above).
- macOS 27.0 SDK headers: `WebKit.framework/Headers/*.h`, `UserNotifications.framework/Headers/UNUserNotificationCenter.h` (`UNUserNotificationCenter` macOS 10.14+), `WKScriptMessageHandlerWithReply.h` (macOS 11.0+).
- [WebKit blog: Meet Web Push](https://webkit.org/blog/12945/meet-web-push/).
- [kofigumbs/multi](https://github.com/kofigumbs/multi) at `b59a415`.
- [tw93/Pake](https://github.com/tw93/Pake) at `c7606f5`.
- Local test on macOS 26.6.2 (25G83).
