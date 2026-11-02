# RAM footprint per stack

Research for [#5](https://github.com/mogui/slotbar/issues/5) of the map [#1](https://github.com/mogui/slotbar/issues/1).

Question: what is the realistic memory footprint of keeping Gmail, Google Chat and Google Calendar loaded across 2 Profiles in native WKWebView vs Electron vs Tauri?

Evidence labels:

- **[measured]** a number with a stated method (even if informal)
- **[anecdote]** a user report without a controlled method
- **[doc]** an official doc, source code or maintainer statement
- **[inference]** derived in this note from the sources above it

## Answer

- The web pages dominate. Gmail, Chat and Calendar each cost hundreds of MB in any engine, and no source shows a stack that makes them light. The stack decides the **fixed baseline** (roughly 50-100 MB for a WebKit app, 150-250 MB for Electron), plus a per-page delta of uncertain sign.
- **Native WKWebView and Tauri share one engine and one process model on macOS.** Memory differences between them come from the host process only (Swift/AppKit vs Rust/tao), a few tens of MB at most. No source measures the two side by side.
- **Electron carries the largest fixed overhead**: main process (Node.js) + GPU process + network service + one renderer per page. On trivial pages its renderers cost about 2x WKWebView processes. On heavy web apps one benchmark found WebKit using *more* than Electron.
- **Profiles do not share page processes in either engine.** 2 Profiles means 2 sets of web content processes, no matter the stack.
- **Rough total for the default config** (2 Profiles, Gmail + Chat kept alive, Calendar on demand, so 4 live pages): about 1-2 GB on any stack, with Electron about 100-150 MB higher in baseline **[inference]**. Opening both Calendars adds 2 more heavy pages.

## Process model per stack

### WebKit (native WKWebView, Tauri on macOS)

- Each web view gets its own web content process until an implementation-defined limit is reached. After that, views in the same `WKProcessPool` share one. **[doc]** ([Apple: WKProcessPool](https://developer.apple.com/documentation/webkit/wkprocesspool)). `WKProcessPool` is marked deprecated from macOS 12, so the app no longer controls this.
- WebKit does not let one WebContent process serve several `WKWebsiteDataStore`s: "We do not support having several WebsiteDataStores sharing the same WebProcess." **[doc]** ([WebKit bug 196041](https://bugs.webkit.org/show_bug.cgi?id=196041)). So each Profile (one data store) gets its own content processes.
- The network process is a singleton that serves several sessions and data stores, so a second Profile adds no extra network process. **[doc]** ([WebKit bug 187188](https://bugs.webkit.org/show_bug.cgi?id=187188)). Older (2018-2019) bug threads, but consistent with the current design.
- Persistent per-Profile data stores need `WKWebsiteDataStore(forIdentifier:)`, available from **macOS 14**. **[doc]** ([Apple](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/init(foridentifier:))). Tauri exposes the same thing as `data_store_identifier` (macOS 14+, iOS 17+, added in `tauri-runtime-wry` 2.3.0). **[doc]** ([Tauri release notes](https://v2.tauri.app/release/tauri-runtime/v2.3.0/))
- Activity Monitor accounting: WebKit charges the GPU process memory used for a tab to the tab itself, while Chrome's task manager leaves out GPU process memory used for web content. WebKit engineers say this "can be confusing to compare." **[doc]** ([WebKit bug 256703](https://bugs.webkit.org/show_bug.cgi?id=256703))

### Electron

- One main process (Node.js), plus "a separate renderer process for each open `BrowserWindow` (and each web embed)". Chromium's GPU and network-service helpers come on top. **[doc]** ([Electron: Process Model](https://www.electronjs.org/docs/latest/tutorial/process-model))
- "Two documents from different profiles or StoragePartitions can never share the same renderer process." Within one partition, Chromium reuses same-site processes only after crossing a soft process limit. A site is scheme + eTLD+1, so `mail.google.com`, `chat.google.com` and `calendar.google.com` are one site. **[doc]** ([Chromium: Process Model and Site Isolation](https://chromium.googlesource.com/chromium/src/+/main/docs/process_model_and_site_isolation.md)). In practice Slotbar would get one renderer per Slot.
- Ferdium maintainer: "Ferdium is consuming a fair amount of RAM, which is due to how electron works and the fact that since we keep everything in containers it needs more memory than a browser which is optimised to share similar resources." **[doc]** ([ferdium discussion #1230](https://github.com/orgs/ferdium/discussions/1230))

## Baseline overhead (stack cost, trivial content)

| Source | Setup | Result | Label |
|---|---|---|---|
| [KeeWeb: Electron alternatives](https://github.com/keeweb/keeweb/wiki/Electron-alternatives) (2020, macOS Catalina) | Same app as Electron build vs minimal WKWebView wrapper, Activity Monitor "Memory", shared helpers excluded | Electron about 215 MB, WKWebView about 112 MB (about 140 MB projected with missing features) | [measured] |
| [Hopp: Tauri vs Electron](https://dev.to/gethopp/tauri-vs-electron-performance-bundle-size-and-the-real-trade-offs-1el4) (MacBook Pro, N=1) | 6 trivial windows | Tauri about 172 MB, Electron about 409 MB. Electron renderers about 2x WKWebView processes | [measured], weak (N=1, method not stated, author picked Tauri) |
| [tauri-apps/benchmark_results](https://github.com/tauri-apps/benchmark_results) | Hello world, max RSS via `time -v` | macOS memory is not recorded (empty in `tauri-recent-macos.json`). Linux figures are WebKitGTK, not applicable here | [measured], not usable for macOS |

Reading: on trivial content WebKit saves roughly 70-240 MB against Electron. Most of the gap is Electron's main + GPU + network processes and its heavier renderers.

## Per-page cost (heavy web apps)

| Source | Setup | Result | Label |
|---|---|---|---|
| [tauri#5889](https://github.com/tauri-apps/tauri/issues/5889) (2023, macOS 12.6.1) | Single 800x600 window, Activity Monitor "Memory", average of 2+ runs | vscode.dev: Tauri 429 / Electron 332 MB. postman.com: Tauri 421 / Electron 337 / Safari 471 / Chrome 381 MB | [measured], informal |
| [WebKit bug 256703](https://bugs.webkit.org/show_bug.cgi?id=256703) | Heavy Flutter/Wasm Google app | Safari about 2 GB vs Chrome about 500 MB (Activity Monitor vs Chrome task manager). Partly an accounting difference (GPU attribution), partly real (dirty memory 1.6 vs 0.9 GB) | [measured], one app |
| Morten Just / Flotato (2021, via [iMore](https://imore.com/chrome-uses-10x-more-ram-safari-macos)) | Gmail + Twitter tabs | Safari 73 MB vs Chrome 730 MB | [measured], disputed: Safari's per-tab WebContent processes reportedly not summed |
| Gmail in Chrome (forums, blogs) | Ad hoc | about 280-500 MB per Gmail tab | [anecdote] |

No source measures Google Calendar or Google Chat on their own. Treat them as Gmail-class (hundreds of MB) until measured **[inference]**.

Reading: for heavy SPAs the WebKit advantage does not hold up. tauri#5889 has WebKit about 90 MB *above* Electron per page. Maintainers in that thread call it a smoke test, not a scientific report ([Beanow, JonasKruckenberg](https://github.com/tauri-apps/tauri/issues/5889)).

## Comparable apps (whole-app totals)

| App | Engine | Report | Label |
|---|---|---|---|
| Wavebox | Chromium | Vendor blog: several Google accounts, 10 services, sleeping tabs bring the total down to about 373 MB (post now 404s) | [measured], vendor, unverifiable |
| Wavebox | Chromium | [wavebox#1441](https://github.com/wavebox/waveboxapp/issues/1441): memory climbs back within 24 h after a restart (Slack tab) | [anecdote] |
| Rambox | Electron | AppSumo user: 2-3 GB. Vendor reply: hibernate/sleep unused apps | [anecdote] |
| ElectronMail | Electron | [#424](https://github.com/vladimiry/ElectronMail/issues/424): 9 mailboxes about 6.5 GB, about 1 GB after restart. Maintainer blames the loaded web clients | [anecdote] |
| Nylas N1 | Electron | [#178](https://github.com/nylas/N1/issues/178): Electron helpers about 643 MB, 1 GB+ with 2 accounts | [anecdote] |

The vendors all point to the same lever: sleeping/hibernating unused services. For Slotbar that is Keep-alive off. Growth over uptime (leaks in the web app) shows up on every stack.

## Estimate for Slotbar

Assumptions: 2 Profiles. Gmail and Chat kept alive, Calendar off (map default). So 4 live heavy pages, plus up to 2 more while Calendar Slots are open. **[inference]**

| Stack | Baseline | 4 live pages | Total (approx.) |
|---|---|---|---|
| Native WKWebView | host about 25-50 MB + shared WebKit Networking/GPU | 4 x 200-500 MB | about 0.9-2.1 GB |
| Tauri | same as native, host in Rust | same as native | same as native, within tens of MB |
| Electron | main + GPU + network about 100-150 MB above WebKit | 4 x 200-450 MB (possibly lower than WebKit per tauri#5889) | about 1.0-2.1 GB |

These ranges overlap almost entirely. On heavy pages the stack choice moves the total by about 5-15%. Keep-alive policy and Gmail-embedded Chat (below) move it by 25-50%. **[inference]**

## Open questions raised

- Gmail's web UI can embed Chat. With a Gmail Slot and a Chat Slot in the same Profile, Chat may be loaded twice. Should Slotbar require or recommend turning off Chat inside Gmail (Gmail setting), or drop separate Chat Slots?
- Is macOS 14 an acceptable minimum? Persistent multi-Profile storage in WKWebView/Tauri depends on `WKWebsiteDataStore(forIdentifier:)`.
- Should non-kept-alive Slots be destroyed (frees the WebContent process) or only hidden after a timeout? This is the main RAM lever.
- Before freezing the stack: a throwaway WKWebView vs Electron prototype loading the real Gmail/Chat/Calendar under 2 Profiles, measured with `footprint` / Activity Monitor (sum of all helper processes) over 24 h. No existing public measurement covers this exact workload.
