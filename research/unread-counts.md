# Source of unread counts for Gmail and Google Chat

Research for [#6](https://github.com/mogui/slotbar/issues/6) of map [#1](https://github.com/mogui/slotbar/issues/1). Researched 2026-11-02.

## Answer

| Service | Primary source | Fallback / supplement | Works while Slot hidden? |
|---|---|---|---|
| Gmail | DOM: the `.bsU` count next to the Inbox link in the left nav | Atom feed `https://mail.google.com/mail/feed/atom` (`<fullcount>`), fetched with the Profile's cookies | DOM: yes, if the Slot is kept alive (Meru, Ferdium do this). Feed: yes, independent of the page |
| Google Chat | Favicon variant (`..._dot_...` vs `..._no_dot_...`) for has-unread | DOM: `div[data-section-type="1"]` (Direct messages) and `="2"` (Spaces) section counts, for the number | Favicon: yes. DOM count: **no** - Chat removes its sidebar while hidden, the count reads 0 |

No source is officially supported for web wrappers. Every DOM selector below has broken at least once in the last 3 years. Design for: read from more than one signal, never report 0 as truth when a signal is missing, and log disagreement.

## Multi-account

Every wrapper studied isolates accounts by giving each one its own persistent storage partition and running a separate page per account; none tries to read several accounts from one page.

- Ferdium: partition `persist:service-<id>` per service ([Service.ts](https://github.com/ferdium/ferdium-app/blob/deabf83/src/models/Service.ts#L519-L520)); a second Gmail account is a second service.
- Meru: `session.fromPartition(\`persist:${accountConfig.id}\`)` per account ([account.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/app/account.ts#L58)); total badge = sum over accounts (`getTotalUnreadCount`, [accounts.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/app/accounts.ts#L758)).
- LibreRambox (Rambox CE fork): `persist:<type>_<id>` per service ([WebView.js](https://github.com/LibreRambox/LibreRambox/blob/108eb21/app/ux/WebView.js#L212)).

This matches Slotbar's Profile model: one Google account per Profile, so each Slot's page reports exactly one account's count, and the status bar badge is a sum over Slots.

Consequence for the Atom feed: inside a single-account Profile, the default `/mail/feed/atom` (account index 0) is that Profile's account. Gmail's `/mail/u/N/...` multi-login paths are not needed and are undocumented.

## Gmail

### DOM (Inbox count in the nav)

- Ferdium: finds `.J-Ke.n0` (Inbox link), climbs two parents, reads the first `.bsU`. Handles priority inbox format `"N:M"` (important : total) ([webview.js](https://github.com/ferdium/ferdium-recipes/blob/d606edec/recipes/gmail/webview.js)).
- Meru: `document.querySelector('div:has(> span > a[href*="#inbox"]) .bsU')?.textContent`, re-run on every body mutation, sends to main only on change ([unread-count.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/preload-gmail/unread-count.ts), [selectors.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/preload-gmail/lib/selectors.ts)). Meru exposes a "first section / total" preference for the two-number format ([ipc.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/app/ipc.ts#L1262-L1275)).
- LibreRambox: reads the digits from the `aria-label` of `.aim .aio span a` every 3 s ([services.json](https://github.com/LibreRambox/LibreRambox/blob/108eb21/resources/services.json)).
- Stability: Ferdium's Gmail recipe history shows count-reading fixes in 2020-09, 2020-10, 2022-03 (counts > 999), 2022-06 (priority inbox), 2023-12, 2024-01, 2026-08 ([history](https://github.com/ferdium/ferdium-recipes/commits/main/recipes/gmail/webview.js)). The `.bsU` class has survived since 2020; the surrounding selectors changed. Meru anchors on `a[href*="#inbox"]`, which is semantic (the URL fragment) rather than an obfuscated class.
- Chat inside Gmail: Ferdium also adds the Chat/Spaces badges rendered in Gmail's sidebar (`div.Xa.bSyoAf span.XU`) to the Gmail count. A 2026-08 fix shows this path silently killed the whole badge for Chat-enabled accounts when `getInnerHTML()` was removed in Chromium 126 ([commit 40cb0ab](https://github.com/ferdium/ferdium-recipes/commit/40cb0ab0)). If Slotbar has a Gmail Slot and a Chat Slot for the same Profile, adding Gmail's Chat badges would double count.
- Hidden page: Meru keeps every account's Gmail view alive, behind the selected one, with Chromium background throttling re-enabled after load ([gmail/index.ts](https://github.com/zoidsh/meru/blob/2c4236a/packages/app/gmail/index.ts#L365-L452)), and still sums counts from all accounts. Ferdium polls every service, visible or not, every 2 s by IPC from the host ([ServicesStore.ts](https://github.com/ferdium/ferdium-app/blob/deabf83/src/stores/ServicesStore.ts#L1454-L1474), [RecipeWebview.ts](https://github.com/ferdium/ferdium-app/blob/deabf83/src/webview/lib/RecipeWebview.ts#L30-L38)). Neither project reports Gmail's nav disappearing while hidden. Not verified on WKWebView.

### Atom feed

- Official doc: "You can access the read-only Gmail inbox feed to receive new message alerts." "This feed is only available for Gmail accounts on Google Workspace domains." OAuth 2.0 with scope `https://mail.google.com/mail/feed/atom` is "the preferred authentication method"; request `GET https://mail.google.com/mail/feed/atom` ([Gmail inbox feed](https://developers.google.com/workspace/gmail/gmail_inbox_feed)). No deprecation notice; no last-updated date on the page.
- Google's own (archived, MV2, 2012) "Google Mail Checker" extension sample fetches `https://mail.google.com/mail/feed/atom?zx=<id>` with the browser's cookies (no OAuth), reads `/gmail:feed/gmail:fullcount` as the unread count, polls with backoff from 1 to 60 minutes ([background.js](https://github.com/GoogleChrome/chrome-extensions-samples/blob/main/_archive/mv2/extensions/gmail/background.js)).
- Implications:
  - Independent of page visibility and DOM changes; works even for a non-kept-alive Gmail Slot as long as the Profile has cookies.
  - Counts the Inbox (unread), not priority sections or Chat.
  - The doc's Workspace-only statement means a consumer `@gmail.com` account may not be served. Not verified.
  - Cookie-authenticated access is not what the doc describes; it relies on Gmail accepting session cookies on that URL. Treat as best effort.

### Gmail API (labels)

- `users.labels.get` on `INBOX` returns `messagesUnread` and `threadsUnread` ([Label resource](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.labels)). Accepted scopes include `gmail.labels` ([labels.get](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.labels/get)), classified **non-sensitive** ([scopes](https://developers.google.com/workspace/gmail/api/auth/scopes)).
- Most stable and documented option, but needs a separate OAuth login and a Google Cloud OAuth client per install or per release, on top of the Profile's web login. Conflicts with "one login per Profile".

### Document title and favicon

- Generic wrappers parse `(N)` from the page title: LibreRambox does this for every service without a custom script (`page-title-updated`, regex `\(([^)]+)\)`) ([WebView.js](https://github.com/LibreRambox/LibreRambox/blob/108eb21/app/ux/WebView.js#L565-L577)). Gmail's title carries a count, but none of the Gmail-specific integrations above use it, and its format is undocumented. Not verified which label's count it shows when the user is not in Inbox.
- Gmail's favicon count is an opt-in setting ("Unread message icon"). Only third-party write-ups found; no Google Help page. Not usable as a default source.

## Google Chat

### Favicon (has-unread)

- google-chat-tauri (Tauri, uses WKWebView on macOS): "Google swaps the favicon between two published variants -- `..._no_dot_64px.png` when everything is read and `..._dot_64px.png` when something is not." It reads `link[rel~="icon"]`'s href, watched by a `MutationObserver` on `<head>` ([chat.js](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/src-tauri/src/inject/chat.js#L191-L210)).
- It "survives the window being hidden to the tray"; the watcher "must not be gated on page visibility" because hidden is when the favicon is the only working signal ([Workarounds.md](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/docs/Workarounds.md#L58-L68)).
- Boolean only, no count. URLs change: Ferdium's 2026-08 rewrite says "the URL for the favicon changed _twice_ within the span of a month" ([commit c30b3a9](https://github.com/ferdium/ferdium-recipes/commit/c30b3a95)). Match on the `_dot_` / `_no_dot_` suffix, not the full URL.

### DOM (section counts)

- Current selectors (2026-08/09): `div[data-section-type="1"]` = Direct messages, `"2"` = Spaces, `"10"` = Shortcuts.
  - Ferdium reads `div.TeR7uc` inside each section, reporting direct and indirect separately ([webview.js](https://github.com/ferdium/ferdium-recipes/blob/d606edec/recipes/hangoutschat/webview.js)).
  - google-chat-tauri reads the count via the section header toggle's `aria-labelledby` (second id = count element), avoiding generated classes ([chat.js](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/src-tauri/src/inject/chat.js#L133-L160)).
  - LibreRambox sums `.zY9JEf[jsname="lv4tIb"]` badges first, then falls back to the two `TeR7uc` section counts ([services.json](https://github.com/LibreRambox/LibreRambox/blob/108eb21/resources/services.json)).
- Stability: Ferdium's Chat count method was rewritten 2021-05, 2024-05 (to favicon) and 2026-08 (to `data-section-type`) ([history](https://github.com/ferdium/ferdium-recipes/commits/main/recipes/hangoutschat/webview.js)). google-chat-tauri saw "the sidebar was rebuilt, and the old count selectors match nothing" on 2026-09-24, and the count read zero with no visible error ([Notes.md](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/docs/Notes.md#L21-L27)).
- Hidden page: "A hidden window is inert, not merely invisible. Chat's router does nothing while the page is hidden, and Chat does not render its navigation either -- so the DOM the unread count scrapes is absent and the count reads zero" ([Notes.md](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/docs/Notes.md#L18-L20)). The sidebar observer has to be re-aimed after every read because Chat removes and rebuilds the sidebar ([Workarounds.md](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/docs/Workarounds.md#L70-L89)).
- Cost: reading the count is about 2 ms on a 4,800-7,000 element page; observer-driven reads plus a 15 s rescan ran 9 reads per 2 min idle vs 120 for a 1 s poll ([Notes.md](https://github.com/ankurk91/google-chat-tauri/blob/595db4d2/docs/Notes.md#L28-L34)). Measured on WebKitGTK.

### Chat API

- `users.spaces.getSpaceReadState` requires user auth with `chat.users.readstate(.readonly)` and returns read state per space; no unread count field ([reference](https://developers.google.com/workspace/chat/api/reference/rest/v1/users.spaces/getSpaceReadState)). Getting a number means listing spaces and messages after each `lastReadTime`, plus a separate OAuth login. Not a practical source.

## Consequences for Slotbar

- Gmail: DOM count (Meru-style anchor on `a[href*="#inbox"]` + `.bsU`, observer-driven) in kept-alive Slots; Atom feed per Profile as an option for non-kept-alive Gmail Slots, if it serves the account type.
- Chat: favicon gives a reliable has-unread dot while hidden; the numeric count is only fresh while the Chat page is rendered. The status bar badge must handle "unread, count unknown" (dot) as a distinct state from a number.
- Keep the last known count when a signal is missing; do not overwrite with 0. Log when favicon says unread and DOM says 0 for more than ~30 s (google-chat-tauri's approach).
- Selectors break silently roughly yearly; keep them in one injectable script that can be updated without a rebuild, or at least in one file.

## Open questions

- Does WKWebView, with the Panel hidden (window ordered out), report `document.visibilityState = "hidden"` and throttle timers for Slotbar's webviews? Determines whether Gmail's DOM count stays fresh and whether Chat's sidebar disappears.
- Does the Atom feed with session cookies still answer for a consumer `@gmail.com` account, given the Workspace-only statement?
- Chat favicon dot: does it cover Spaces activity, or only direct messages and mentions?
- Should the Gmail Slot's count include Chat badges shown in Gmail, when the same Profile also has a Chat Slot?
