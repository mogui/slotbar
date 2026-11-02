# Google login inside an embedded webview

Research for ticket #4 of the Slotbar map (#1). Researched 2026-11-02.

**Question:** Does Google sign-in (password, 2FA, passkeys, Workspace SSO) work inside a WKWebView, Electron and Tauri webview today? Which user-agent or configuration avoids the "This browser or app may not be secure" block, and what are the known breakages?

## Answer

- **Password + 2FA (TOTP, SMS, phone prompt):** works in all three stacks today, with a spoofed user agent. Evidence is from actively maintained open-source wrappers, not from Google, which forbids the practice.
  - WKWebView (macOS): a desktop **Firefox** UA is the strongest current evidence (google-chat-tauri, Sept-Oct 2026, personal and Workspace accounts). A Safari UA is plausible but I found no 2025-2026 primary report for it.
  - Electron: a Chrome UA string alone is **not** enough in 2026. Reports say Google also checks Client Hints and/or `window.chrome`. The reports conflict on which signal matters.
  - Tauri: on macOS it is WKWebView, so the WKWebView answer applies.
- **Passkeys and security keys:** do **not** work for `google.com` in an unsigned Slotbar in any stack. The Google flow has to fall back to "Try another way" (password + second factor).
- **Workspace SSO (SAML / third-party IdP):** works if two conditions hold. The IdP hosts must stay inside the Slot (link routing), and the webview must not change the UA in the middle of a navigation (an Electron-specific trap).
- **Policy status:** every UA-spoofing workaround violates Google's written policy. Google can break it at any time with no notice.

## Google's policy (primary, verified)

| Date | Source | What it says | Status |
|---|---|---|---|
| 2019-04-18 | [Google Security Blog: Better protection against Man in the Middle phishing attacks](https://security.googleblog.com/2019/04/better-protection-against-man-in-middle.html) | Announces blocking of sign-ins from embedded browser frameworks. I could fetch only the title and date, not the body. | Historical; still the stated rationale |
| 2020-08-28 | [Google Developers Blog: Guidance for our effort to block less secure browsers and apps](https://developers.googleblog.com/2020/08/guidance-for-our-effort-to-block-less-secure-browser-and-apps.html) | "Google Account sign-ins from all embedded frameworks will be blocked starting on January 4, 2021." Names CEF. "The browser must not use another browser's User-Agent string." Test header: `Google-Accounts-Check-OAuth-Login:true` on requests to `accounts.google.com`. | Current rule for **Google Account sign-in** (the case Slotbar is in) |
| 2021-06 | [Google Developers Blog: Upcoming security changes to Google's OAuth 2.0 authorization endpoint in embedded webviews](https://developers.googleblog.com/upcoming-security-changes-to-googles-oauth-20-authorization-endpoint-in-embedded-webviews/) | OAuth requests from embedded webviews have been blocked since 2021-09-30 with `disallowed_useragent`. WKWebView is named explicitly. Recommends the system browser or SFSafariViewController. | Current; applies to **OAuth clients**. Slotbar is not an OAuth client. |
| Page modified 2026-08-05 | [OAuth 2.0 Policies: Use secure browsers](https://developers.google.com/identity/protocols/oauth2/policies) | "A developer must not direct a Google OAuth 2.0 authorization request to an embedded user-agent under the developer's control." Embedded user-agents include libraries that can inject scripts, alter routing or read session cookies. | Current (OAuth) |
| Undated, live | [Google Account Help: Sign in with a supported browser](https://support.google.com/accounts/answer/7675428) | Sign-in may be blocked from browsers that have JavaScript off, carry unsafe extensions, are "controlled through software automation", or are "embedded in a different application". | Current (end-user page) |
| Undated, live | [Sign In With Google: supported browsers](https://developers.google.com/identity/gsi/web/guides/supported-browsers) | "Android and iOS webviews are not supported for user sign-in." Supported: the latest two versions of Chrome, Edge, Firefox and Safari. | Current (GIS library) |

**Implication (inferred):** Slotbar loads `accounts.google.com` directly to get a Gmail/Calendar/Chat web session. Of the policies above, that falls under the 2020 "embedded frameworks" rule, not the OAuth rule. Detection is heuristic and unpublished. Spoofing violates the rule, and the map already accepts that risk ("User-agent spoofing (e.g. as Safari) is acceptable").

## What works in practice, per stack

### WKWebView (native Swift, and Tauri on macOS)

- **Default UA (verified locally, macOS 26.6.2):** a bare `WKWebView` reports `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)`. That UA has no `Version/...` and no `Safari/...` token, and `window.chrome` is undefined. Google can tell this apart from Safari by the UA alone. Spoofing is required.
- **Firefox UA, working in 2026 (verified source, behaviour as claimed by the maintainer):** [ankurk91/google-chat-tauri](https://github.com/ankurk91/google-chat-tauri) (Tauri v2; WKWebView on macOS 15+, WebView2 on Windows, WebKitGTK on Linux). It sets the webview-level UA on every platform, macOS included, to `Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:155.0) Gecko/20100101 Firefox/155.0`. Sources: [`src-tauri/src/features/user_agent.rs`](https://github.com/ankurk91/google-chat-tauri/blob/main/src-tauri/src/features/user_agent.rs) and `window.rs` (`.user_agent(&crate::features::user_agent::spoofed())`). The README says "a personal Google account and a paid Google Workspace one both work". The code comment says the Firefox UA "reliably passes both sign-in and the full Chat UI". The `GOOGLE_CHAT_UA` env var overrides the UA without a rebuild, and the maintainer calls it "the first thing to reach for when sign-in misbehaves" ([docs/Workarounds.md](https://github.com/ankurk91/google-chat-tauri/blob/main/docs/Workarounds.md)). Last UA bump: 2026-09-05 ("spoof Firefox 155, not 134").
  - The same maintainer's Electron app never fully fixed the block with UA changes ([google-chat-electron#52](https://github.com/ankurk91/google-chat-electron/issues/52), 2021-2022). In 2026-09 they wrote that the Tauri rebuild "does not face this issue".
- **Safari UA (inferred, not verified):** a WebKit engine that claims to be Safari matches its real engine fingerprint better than a Firefox claim does. Still, I found no 2025-2026 primary report of a Safari UA passing on macOS WKWebView. Older Stack Overflow answers suggest `customUserAgent` as a workaround for `disallowed_useragent`, but they cover OAuth on iOS (outdated context).
- **Breakage seen in Tauri/WKWebView:** [tauri#11612](https://github.com/tauri-apps/tauri/issues/11612) (opened 2024-11, active until 2026-05). On macOS 14 the Google login succeeds but the Google Docs editor fails to load afterwards. On WebView2, Google Sheets collides with Tauri's global `window.ipc`. The maintainer won't fix this in 2.x ("I don't think google docs is worth the risk"). This does not affect Gmail, Calendar or Chat directly, but it shows Google apps can break on injected globals.

### Electron

- **A UA string alone is not enough in 2026 (verified source, behaviour claimed).** Two current wrappers reverse-engineered the block and reached different conclusions:
  - [dmetzner/earshot](https://github.com/dmetzner/earshot) `main.js` (active 2026-11). The comment says Google "sniffs" Client Hints: "Electron sends NO Sec-CH-UA* hints, and their absence is itself the tell". The app sets a Chrome 140 UA and injects the full `sec-ch-ua*` header set in `session.webRequest.onBeforeSendHeaders`.
  - [notihub v1.3.5 release notes](https://github.com/Thuong180702/notihub/releases/tag/v1.3.5) (Aug, year not shown, probably 2026). A correct Chrome UA, matching `Sec-CH-UA` and `navigator.userAgentData` were all still blocked. Populating `window.chrome` (Electron leaves it empty) was "both necessary and sufficient".
  - **Conclusion (inferred):** Google fingerprints more than the UA, and the signals shift over time. Each Electron wrapper fixes the check it happened to hit.
- **Ferdium (verified source):** [`src/models/UserAgent.ts`](https://github.com/ferdium/ferdium-app/blob/develop/src/models/UserAgent.ts) switches to a "chromeless" UA (Chrome version stripped) after `did-navigate` to `https://accounts.google.com`, and restores the normal UA elsewhere. The default UA is a plain Chrome UA without the `Electron/` token ([`userAgent-helpers.ts`](https://github.com/ferdium/ferdium-app/blob/develop/src/helpers/userAgent-helpers.ts)).
- **Workspace SSO breakage (verified, 2026):** Ferdium [#1973](https://github.com/ferdium/ferdium-app/issues/1973) reported company Google logins ending on a grey screen. The fixes were [PR #2261](https://github.com/ferdium/ferdium-app/pull/2261) (merged 2026-02-03) and [PR #2396](https://github.com/ferdium/ferdium-app/pull/2396) (merged 2026-04-25). From #2396: setting `webview.userAgent` in `will-navigate` "calls SetUserAgentOverride() in Electron while a navigation is pending, which cancels the navigation. This broke any cross-origin form POST to accounts.google.com, including SAML ACS endpoints". Rule: set the UA once at creation, or only after navigation completes.

### Cross-stack breakages

- **Automation / debugging ports:** sign-in is refused while the engine has a remote-debugging/CDP port open ([TierTek/omarchy-tektube#2](https://github.com/TierTek/omarchy-tektube/issues/2), 2026-10). This matches Google's "controlled through software automation" criterion. Slotbar must not enable `--remote-debugging-port`-style inspection in release builds. On WKWebView, whether `isInspectable = true` triggers the block is untested.
- **WebView2 (Windows, for reference):** default-UA panes are rejected at `accounts.google.com/v3/signin/rejected` ([theogmiguel/houston#388](https://github.com/theogmiguel/houston/issues/388), 2026-10, Tauri), and so are the panes in [CherryHQ/cherry-studio#21774](https://github.com/CherryHQ/cherry-studio/issues/21774) (2026-10). Not relevant to a macOS-only Slotbar.
- **Sign-in hops through country domains:** `accounts.google.co.in/SetSID` and equivalents. If routing treats them as external links, the system browser finishes the login and the Slot stays signed out (google-chat-tauri [docs/Notes.md](https://github.com/ankurk91/google-chat-tauri/blob/main/docs/Notes.md), "Sign-in" section).
- **Third-party IdP (Okta, Entra ID, Ping):** these redirect to an org-specific host the app cannot know ahead of time. google-chat-tauri solves it with a "Temporarily Open Every Link in This Window" mode that lasts 5 minutes (README).
- **Sign-out lands on a marketing page:** `accounts/Logout?continue=...` can redirect to `workspace.google.com/.../gmail/`, which is a dead end unless the app offers a "go home" action (Notes.md).

## Passkeys and security keys (WebAuthn)

### WKWebView (verified)

- Apple entitlement [`com.apple.developer.web-browser.public-key-credential`](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.web-browser.public-key-credential) (macOS 13.3+): "lets your app make registration and assertion requests for passkeys and security keys for any relying party identifier. Only add this entitlement if your app can act as a user's web browser."
  - Request criteria: the app must declare the HTTP/HTTPS schemes, offer a URL field, search or bookmarks on launch, and navigate to arbitrary URLs without redirecting.
  - Getting it requires the Account Holder role, a dedicated request form and Apple review. It is delivered as a managed capability, which means a signed app with a provisioning profile.
  - Slotbar fails on two counts. It is not a general browser (Slots are fixed), and it ships unsigned.
- Without that entitlement, WebAuthn for a third-party RP (`google.com`) needs an Associated Domains `webcredentials` link between the app and the RP. Google will not list Slotbar's team ID. An Apple DTS forum thread from 2026-06 ([thread 829169](https://developer.apple.com/forums/thread/829169)) confirms the request process for a macOS WKWebView wrapper of web apps. It does not suggest any route other than the entitlement.
- **Local probe (verified, macOS 26.6.2, unsigned `swift` script host, `https://example.com`):**
  - `PublicKeyCredential` exists.
  - `isUserVerifyingPlatformAuthenticatorAvailable()` returns `false`.
  - `navigator.credentials.get({publicKey: ...})` rejects with `NotAllowedError: The request is not allowed by the user agent or the platform in the current context`.

### Electron (verified docs, 2026)

- [`app.configureWebAuthn`](https://www.electronjs.org/docs/latest/api/app) (macOS only, docs say added in 45.0.0; a 2026-08 PR claims 41.5.0). Until it is called, `isUserVerifyingPlatformAuthenticatorAvailable()` is `false`.
  - The `touchID` option creates device-bound, non-synced credentials and needs the `keychain-access-groups` entitlement.
  - The `platformPasskeys` option (iCloud Keychain via `ASAuthorizationController`) needs a signed app, a provisioning profile and `webcredentials:<domain>` Associated Domains. The RP domain must serve an AASA file listing the app. "Ad-hoc and unsigned builds don't qualify."
  - **Result for google.com:** impossible (Google's AASA won't list Slotbar). Touch ID passkeys would also need a signed build. USB security keys are reported "still unusable" ([different-ai/openwork#3460](https://github.com/different-ai/openwork/pull/3460), 2026-08).
- Long-standing issue: [electron#24573](https://github.com/electron/electron/issues/24573), open since 2020-07.

### Consequence for Google sign-in (inferred)

- Accounts that sign in with a passkey by default must use "Try another way", then password + second factor. Google offers that fallback for normal accounts.
- Accounts in **Google Advanced Protection**, or Workspace accounts whose admin enforces security keys/passkeys only, are expected to be unable to sign in to Slotbar at all. This is unverified, because I did not test against a real enforced account.
- Signing in through `ASWebAuthenticationSession` or the system browser does not help (inferred). Those flows use the Safari / system cookie store, not the Slot's WKWebView data store, so the Gmail web session would not carry into the Slot.

## Current vs outdated

| Claim | Status |
|---|---|
| OAuth-in-webview block (`disallowed_useragent`, 2021-09-30) | Current, but it targets OAuth clients. Many "Google blocks WKWebView" answers mix it up with the Account sign-in block. |
| Embedded-framework Account sign-in block (2021-01-04) and no-UA-spoofing rule | Current policy |
| "Set `customUserAgent` and it works" (Stack Overflow / iOS / OAuth era) | Outdated as a general claim. Still true for WKWebView with a desktop Firefox UA as of 2026-10 (google-chat-tauri). |
| "Strip `Electron/` from the UA and it works" (2019-2022 Electron wrappers) | Outdated. In 2026 you also need Client Hints and/or `window.chrome`. |
| Electron has no WebAuthn platform authenticator | Outdated since `app.configureWebAuthn` (2026). Still no usable path for google.com in an unsigned app. |

## Open points not resolved by this research

- Whether a Safari UA (with `Version/x Safari/605.1.15`) passes as reliably as the Firefox UA in WKWebView today. Needs a quick manual test.
- Whether WKWebView `isInspectable = true` triggers the automation block.
- Behaviour with Advanced Protection or security-key-enforced Workspace accounts.
