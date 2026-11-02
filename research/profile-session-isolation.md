# Persistent session isolation per Profile

Research for [#3](https://github.com/mogui/slotbar/issues/3) of the map [#1](https://github.com/mogui/slotbar/issues/1).

Question: how do we give each Profile its own persistent cookie/storage container in WKWebView (`WKWebsiteDataStore(forIdentifier:)` or alternatives)? Minimum macOS version, persistence across restarts, deletion, and the equivalent in Electron (`partition`) and Tauri.

Evidence labels:

- **[doc]** official documentation or vendor engineering blog
- **[source]** read in the project's source code (current `main`/`dev`, not necessarily the shipped OS build)
- **[inference]** derived in this note from the sources above it
- **[unverified]** a report or claim with no confirming primary source; needs a prototype check

Sources read on 2026-11-02.

## Answer

- **Native WKWebView:** one `WKWebsiteDataStore(forIdentifier: UUID)` per Profile, set on the `WKWebViewConfiguration` of every Slot web view of that Profile. Requires **macOS 14 Sonoma**. Persistent on disk, enumerable with `fetchAllDataStoreIdentifiers`, deletable with `remove(forIdentifier:)`. **[doc]**
- **Below macOS 14** there is no public API for more than one persistent store: only `default()` (one persistent store) and `nonPersistent()` (in-memory, lost on quit). **[doc]** Supporting macOS 13 or earlier with persistent Profiles would mean private SPI. **[inference]**
- **Tauri (macOS):** the same API, exposed as `WebviewBuilder::data_store_identifier([u8; 16])` (macOS 14+), plus `AppHandle::fetch_data_store_identifiers` and `AppHandle::remove_data_store`. `data_directory` has no effect on macOS. On macOS 13 wry **silently falls back to the default store**, so all Profiles would share cookies. **[source]**
- **Electron:** `webPreferences.partition = "persist:<name>"` or `session.fromPath(absPath)` (Electron 25+). Persistent on disk under `<sessionData>/Partitions/<lowercased, escaped name>`. No minimum-OS constraint beyond Electron's own (macOS 13 Ventura+ for current releases). No "delete session" API: `ses.clearData()` empties it; the directory stays. **[doc]** / **[source]**
- **Recommendation for the spec [inference]:** key each Profile by a UUID generated at Profile creation and stored in settings. The same UUID works as WKWebView/Tauri identifier and as an Electron partition name (`persist:<uuid>`). Set minimum macOS to 14 if the stack is WKWebView or Tauri.

## Native WKWebView

### API surface and availability

| API | Purpose | macOS | Label |
|---|---|---|---|
| `WKWebsiteDataStore.default()` | the one app-wide persistent store | 10.11 | [doc] |
| `WKWebsiteDataStore.nonPersistent()` | in-memory store, nothing written to disk | 10.11 | [doc] |
| `WKWebsiteDataStore(forIdentifier: UUID)` | persistent store for a profile; created if missing | **14.0** | [doc] |
| `WKWebsiteDataStore.fetchAllDataStoreIdentifiers(_:)` / `allDataStoreIdentifiers` (async) | list existing identified stores, without creating any | **14.0** | [doc] |
| `WKWebsiteDataStore.remove(forIdentifier:completionHandler:)` / `remove(forIdentifier:) async throws` | delete a store | **14.0** | [doc] |
| `identifier: UUID?` | the store's UUID; `nil` for `default()` and `nonPersistent()` | **14.0** | [doc] |
| `httpCookieStore` | per-store cookie access | 10.13 | [doc] |
| `removeData(ofTypes:modifiedSince:)` | wipe data inside a store without deleting it | 10.11 | [doc] |

Sources: [WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore), [init(forIdentifier:)](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/init(foridentifier:)), [fetchAllDataStoreIdentifiers(_:)](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/fetchalldatastoreidentifiers(_:)), [remove(forIdentifier:completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/remove(foridentifier:completionhandler:)), [identifier](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/identifier). Availability taken from the docs' platform metadata (iOS 17.0, macOS 14.0).

- Apple's class overview: "To implement profile browsing, create a persistent data store using the `init(forIdentifier:)` method, passing an identifier that you use to identify the data store." The store must be assigned to `WKWebViewConfiguration.websiteDataStore` **before** the web view is created. **[doc]**
- `init(forIdentifier:)`: "If the data store for the unique identifier you provide does not exist, the system creates and returns it." It throws (an ObjC `NSInvalidArgumentException`, not a Swift error) if the identifier is nil or invalid. **[doc]** / **[source]** ([WKWebsiteDataStore.mm](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStore.mm))
- WebKit blog (Sihui Liu, 2023-08-30): "Before macOS 14 and iOS 17, WebKit clients could have multiple non-persistent data stores, but only one persistent data store." The API does not cover per-site settings, bookmarks or history. **[doc]** ([Building Profiles with new WebKit API](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/))
- No WWDC session covers this API. WWDC23 session 10119 ("What's new in Safari extensions") talks about Safari Profiles, not the WebKit API. **[doc]** ([WWDC23 10119](https://developer.apple.com/videos/play/wwdc2023/10119/))

### Sharing one Profile across Slots

- Several web views can use the same `WKWebsiteDataStore`. Calling `init(forIdentifier:)` again with the same UUID returns the same store (`dataStoreForIdentifier` looks up an existing instance first). **[source]** ([WebsiteDataStore.cpp](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/WebsiteData/WebsiteDataStore.cpp))
- Slot web views of different Profiles never share cookies or storage. This matches the GLOSSARY definition of Profile. **[inference]**

### Persistence across restarts

- Stores created with an identifier are persistent. The blog says the identifier lets the app retrieve the same store on next launch: "You will need to remember the identifier so the data store can be retrieved." **[doc]**
- On-disk location ([WebsiteDataStoreCocoa.mm](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/WebsiteData/Cocoa/WebsiteDataStoreCocoa.mm), `defaultWebsiteDataStoreRootDirectory`) **[source]**:
  - non-sandboxed app (the unsigned Slotbar `.app`): `~/Library/WebKit/<app or process identifier>/WebsiteDataStore/<UUID>/`
  - sandboxed app: no per-app component, so `<container>/Library/WebKit/WebsiteDataStore/<UUID>/` **[inference]** (path of `NSLibraryDirectory` inside the sandbox container)
  - cookies inside it: `Cookies/Cookies.binarycookies`
- `fetchAllDataStoreIdentifiers` lists the subdirectories of that root that parse as UUIDs. It is a directory scan, so it also finds orphaned stores left by deleted Profiles. **[source]**
- A 2025 Apple Developer Forums post reports identified stores losing cookies and caches on relaunch. It has no replies and no repro details. **[unverified]** ([thread 777676](https://developer.apple.com/forums/thread/777676)). A likely cause is session cookies (no expiry), which are never persisted, or a new UUID generated each launch. **[inference]** The prototype must check that Google login survives a quit and relaunch.

### Deletion

- Doc: "Release any `WKWebView` instances using the data store before you call this method. If the system cannot complete removal of the data store, this throws an error." **[doc]**
- Blog: removal "can fail if the specified data store is still in use, for example, by an active `WKWebView` ... or if there is a file system error." **[doc]**
- Source (`WebsiteDataStore::removeDataStoreWithIdentifier`) **[source]**:
  - fails with "Data store is in use" while the store has active pages
  - also fails with "Data store is in use (by network process)" if the live store object still has a network process attached. A FIXME says WebKit should remove the session instead.
  - on success it clears that store's `NSURLCredentialStorage` and deletes the `<UUID>` directory
- So deleting a Profile in the same app run that used it may fail even after its web views are closed. A safe flow is: close the Profile's Slots, drop every reference to the store, call `remove`; if that fails, record the UUID as pending deletion and remove it at the next launch before any store is created. **[inference]**
- Wiping without deleting ("log out of this Profile") works on macOS 10.11+ with `removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)`. **[doc]**

### Alternatives below macOS 14

- `nonPersistent()` per Profile: isolated, but forgets every login on quit. This fails the "one login per Profile" preference. **[doc]** / **[inference]**
- `_WKWebsiteDataStoreConfiguration` (custom per-store directories) is private SPI. It is not documented by Apple; this note did not verify its behaviour. **[unverified]**

## Tauri (v2, macOS = wry on WKWebView)

Version read: tauri 2.12.5, wry 0.57.1.

- `WebviewBuilder::data_store_identifier(id: [u8; 16])` and `WebviewWindowBuilder::data_store_identifier`: "Can be used as a replacement for data_directory not being available in WKWebView." macOS 14+ / iOS 17+; "Windows / Linux / Android: Unsupported." Added in tauri 2.2.0 (PR #11798). **[doc]** ([docs.rs WebviewBuilder](https://docs.rs/tauri/latest/tauri/webview/struct.WebviewBuilder.html), [tauri CHANGELOG](https://github.com/tauri-apps/tauri/blob/dev/crates/tauri/CHANGELOG.md))
- wry maps it straight to `dataStoreForIdentifier:`. The selection logic in `src/wkwebview/mod.rs` is: `incognito` -> `nonPersistentDataStore`; identifier set **and** `os_major_version >= 14` -> `dataStoreForIdentifier`; otherwise -> `defaultDataStore`. **[source]** ([wry wkwebview](https://github.com/tauri-apps/wry/blob/dev/src/wkwebview/mod.rs))
  - So on macOS 13 every Profile **silently shares the default store**, with no error. Slotbar must refuse to run, or block a second Profile, below 14. **[inference]**
- `data_directory(PathBuf)` exists but nothing in wry's `src/wkwebview/` reads it. It only takes effect on Windows (WebView2) and Linux (WebKitGTK). **[source]**
- Lifecycle, apple-only on `AppHandle` (main thread): `fetch_data_store_identifiers() -> Vec<[u8;16]>` and `remove_data_store(uuid)`. Both wrap the Apple calls, so the same "in use" failure modes apply. **[source]** ([tauri app.rs](https://github.com/tauri-apps/tauri/blob/dev/crates/tauri/src/app.rs), wry `mod.rs`)
- `Webview::clear_all_browsing_data()`: on macOS "clears the `WKWebsiteDataStore` of this webview. Webviews created with a custom `data_store_identifier` have their own store, so only that store is affected." **[source]** (doc comment in `crates/tauri/src/webview/mod.rs`)
- Several webviews in one window (`Window::add_child`) is behind the `unstable` cargo feature on desktop. One window per Slot, or swapping webviews in the Panel, avoids that. **[source]** ([tauri webview/mod.rs](https://github.com/tauri-apps/tauri/blob/dev/crates/tauri/src/webview/mod.rs), `window/mod.rs`)

## Electron (Chromium)

Version read: Electron `main` docs (latest release v45.2.1).

- `webPreferences.partition`: "If `partition` starts with `persist:`, the page will use a persistent session available to all pages in the app with the same `partition`. If there is no `persist:` prefix, the page will use an in-memory session. By assigning the same `partition`, multiple pages can share the same session." Works the same on `BrowserWindow` and `WebContentsView`. **[doc]** ([web-preferences.md](https://github.com/electron/electron/blob/main/docs/api/structures/web-preferences.md), [web-contents-view.md](https://github.com/electron/electron/blob/main/docs/api/web-contents-view.md))
- `session.fromPartition(partition)` returns the same `Session` for the same string. `session.fromPath(absolutePath)` makes a session at an arbitrary absolute directory; it shipped in Electron 25.0.0 (PR #37604). **[doc]** ([session.md](https://github.com/electron/electron/blob/main/docs/api/session.md), [v25.0.0 release notes](https://github.com/electron/electron/releases/tag/v25.0.0))
- On-disk location: `app.getPath('sessionData')` (defaults to `userData`) + `Partitions/` + `MakePartitionName(name)`. `MakePartitionName` is `EscapePath(ToLowerASCII(name))`. **[source]** ([electron_browser_context.cc](https://github.com/electron/electron/blob/main/shell/browser/electron_browser_context.cc))
  - Partition names are **case-insensitive on disk**: `persist:Work` and `persist:work` share one directory. UUID names avoid that. **[inference]**
  - `sessionData` can only be moved before the app's `ready` event. **[doc]** ([app.md](https://github.com/electron/electron/blob/main/docs/api/app.md))
- Inspect and wipe: `ses.isPersistent()`, `ses.getStoragePath()` (null for in-memory), `ses.clearStorageData({storages})`, and `ses.clearData({dataTypes, origins})`, which is "more thorough". **[doc]**
- No API deletes a persistent session or its directory. To remove a Profile fully: `clearData()`, then delete `<sessionData>/Partitions/<name>` once no page uses it (or at next launch). **[inference]**
- Minimum OS: current Electron supports macOS Ventura (13) and up. **[doc]** ([README](https://github.com/electron/electron/blob/main/README.md))

## Comparison

| | Native WKWebView | Tauri (macOS) | Electron |
|---|---|---|---|
| Per-Profile persistent store | `WKWebsiteDataStore(forIdentifier:)` | `data_store_identifier` | `partition: "persist:<id>"` / `fromPath` |
| Key type | UUID | 16 bytes (UUID) | string (lowercased) / absolute path |
| Minimum macOS for isolation + persistence | 14 | 14 (silent fallback to shared default below) | Electron's floor (13) |
| Enumerate stores | `fetchAllDataStoreIdentifiers` | `AppHandle::fetch_data_store_identifiers` | none (scan `Partitions/`) |
| Delete store | `remove(forIdentifier:)`, fails while in use | `AppHandle::remove_data_store`, same | none; `clearData()` + delete dir |
| Wipe without delete | `removeData(ofTypes:modifiedSince:)` | `clear_all_browsing_data()` | `clearData()` |

## Open points for the prototype

- Google login in an identified store survives quit and relaunch (addresses the unverified forum report).
- `remove(forIdentifier:)` succeeds after closing a Profile's web views in the same run, or only at the next launch (network-process check).
- Whether the unsigned, non-sandboxed build puts stores under `~/Library/WebKit/<bundle id>/`, as the source suggests.
