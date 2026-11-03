# Slotbar

## What it is

Slotbar is a macOS menu bar app that keeps Gmail, Google Calendar, Google Chat or any other web app in a Panel that slides in from a screen edge (right by default; left, top or bottom in Settings).

- Each web app lives in a Slot: a starting URL plus a Profile.
- A Profile is one Google account with its own isolated session; all Slots of the same account share it, so you sign in once per Profile.
- `Ctrl+Option+S` (or a click on the menu bar icon) shows and hides the Panel.
- `Cmd+1` ... `Cmd+9` switch to Slot 1 ... 9 while the Panel is focused.

Requires macOS 14 or later.

## Install

1. Download `Slotbar-X.Y.Z.zip` from [Releases](https://github.com/mogui/slotbar/releases).
2. Check the SHA-256 against the one in the release notes:
   ```sh
   shasum -a 256 ~/Downloads/Slotbar-X.Y.Z.zip
   ```
3. Unzip it and move `Slotbar.app` to `/Applications`.
4. Remove the quarantine flag, then open the app:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Slotbar.app
   open /Applications/Slotbar.app
   ```

Alternative to step 4: open the app once, then go to System Settings > Privacy & Security and click "Open Anyway". On macOS 15 and later, Control-click > Open no longer bypasses the warning.

The app must live in `/Applications` or `~/Applications`: notifications do not work from anywhere else. Slotbar shows a "Move Slotbar to Applications" alert at every launch until it is there.

## First run

Slotbar starts with a preset in a Profile named "Default":

| Slot | URL | Keep-alive |
|---|---|---|
| 1 | `https://mail.google.com/` | on |
| 2 | `https://calendar.google.com/` | off |
| 3 | `https://chat.google.com/` | on |

1. Allow notifications when macOS asks.
2. Open the Panel with `Ctrl+Option+S` or the menu bar icon.
3. Sign in inside the Gmail Slot. Calendar and Chat use the same session.

Tip: if you have a Chat Slot, turn off Chat in Gmail (Gmail Settings > Chat and Meet > Chat: Off) to avoid loading Chat twice.

## Signing in

- Sign in with password + 2FA.
- On a passkey or security-key prompt, choose "Try another way".
- Accounts with Advanced Protection and Workspace accounts that enforce security keys are not supported as Profiles.

Slotbar presents a desktop Firefox user agent to Google. To override it:

```sh
defaults write io.github.mogui.slotbar UserAgent "<string>"
```

Then quit and relaunch Slotbar. To go back to the built-in user agent:

```sh
defaults delete io.github.mogui.slotbar UserAgent
```

## Usage

### Rail

The Rail is the strip on the Panel's outer side: one icon per Slot (favicon, Profile color dot, unread badge), then a gear that opens Settings. Click an icon to switch to that Slot; hover for its label and shortcut.

Right-click a Slot icon for:

- Go home
- Open current page in browser
- Reload
- Notifications (on/off for that Slot)

### Shortcuts

| Keys | Action |
|---|---|
| `Ctrl+Option+S` | Show / hide the Panel (global, change it in Settings > General) |
| `Cmd+1` ... `Cmd+9` | Switch to Slot N |
| `Cmd+Shift+H` | Go home (active Slot) |
| `Cmd+Shift+O` | Open current page in browser (active Slot) |
| `Cmd+R` | Reload (active Slot) |
| `Cmd+W` | Hide the Panel; in a popup window, close that window |
| `Cmd+,` | Settings |
| `Cmd+Q` | Quit Slotbar |

Esc is left to the page. If the global hotkey cannot be registered, Settings > General shows a warning and the menu bar icon's right-click menu shows "Hotkey unavailable"; clicking the icon still works.

### Slots

Settings > Slots sets, per Slot:

- **Keep-alive**: the Slot loads at launch and stays loaded. Without it, the Slot loads on first open and unloads 5 minutes after it was last shown (sooner under memory pressure).
- **Notifications**: whether the Slot can post macOS notifications.

Links to another Slot of the same Profile open in that Slot. Other links open in your default browser. Google sign-in pages and popups such as Gmail's pop-out compose stay in Slotbar.

## Upgrade

1. Quit Slotbar (menu bar icon right-click > Quit Slotbar).
2. Replace `Slotbar.app` in `/Applications` with the new one.
3. Remove the quarantine flag again and open it:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Slotbar.app
   open /Applications/Slotbar.app
   ```

Settings and sessions are kept. With Open at login on, macOS may show a "Login item added" banner after each upgrade.

## Build from source

Requires Xcode (Swift 6).

```sh
scripts/build-app.sh release   # universal arm64 + x86_64, ad-hoc signed
swift test                     # unit tests
```

The app is written to `build/Slotbar.app`. `scripts/build-app.sh debug` builds a debug app with the Web Inspector enabled.

## Limitations

- The app is unsigned (ad-hoc signature), so every download needs the quarantine step above.
- No passkeys or security keys.
- Notifications and unread badges come only from loaded Slots.
- Calls and huddles (Meet, Chat): use the browser.
- Google may block sign-in inside embedded web views at any time.
