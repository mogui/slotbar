# Built-in palettes, system follows appearance live (#43, criterion 1)

Built-in palettes `system`, `solarizedLight`, `solarizedDark`, `dracula`, `nord` (16 ANSI colors, foreground, background, cursor, selection); `system` follows the effective appearance live; default `system`.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence; system-live user-reported (observed by the user, no recorded artifact)

## Sub-features

- `43-1-each` each theme changes background/foreground and ANSI colors.
- `43-1-system-live` with `system`, switching macOS Light/Dark repaints at once.
- `43-1-default` a new settings file has `theme: system`.

## How to get to it (user POV)

- Settings > Terminal > Theme.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, type `for i in {0..15}; do printf "\e[48;5;${i}m  "; done; echo` + Return.

- **Each theme.** For each theme: click `Settings`, click the Theme popup with `--restore-window`, `oc press-key --key Down`/`Up` to the theme, `Return`; `V settings` shows it; click `Terminal`, `V shot 43-1-<theme>`. Backgrounds and the 16 swatches differ between shots; dracula background ≈ #282a36, nord ≈ #2e3440, solarizedDark ≈ #002b36, solarizedLight ≈ #fdf6e3. Sampled shot pixels carry the display's color profile (dracula samples as about #343846): compare shots with each other, not with exact hex.
- **System live.** Theme `system`; the user switches System Settings > Appearance (or with consent `osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'`, which changes the user's Mac: ask). `V shot` before/after differs without touching Slotbar.
- **Default.** `V settings` on a fresh launch: `"theme" : "system"`.

## Gotchas

- Flipping the system appearance affects the user's whole Mac; always ask, and flip it back.
- The Theme popup refuses `set-value` (`value_not_settable`) and background clicks; it needs one foreground click (`--restore-window`, user consent), then keys.
- Picker labels: Follow system, Solarized Light, Solarized Dark, Dracula, Nord.
- `system` is its own pair: light bg #ffffff / fg #000000, dark bg #1e1e1e / fg #d4d4d4 (xterm ANSI on both). Hidden tabs repaint when shown.
