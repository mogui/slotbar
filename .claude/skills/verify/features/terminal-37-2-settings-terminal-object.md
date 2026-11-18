# Settings terminal object (#37, criterion 2)

`settings.json` gains an optional `terminal` object with every field and default; a file without it reads as off with defaults and `schemaVersion` 1; out-of-range `fontSize` and unknown `theme` are handled; encode/decode round-trips.

Status: pending

## Sub-features

- `37-2-tests` SettingsStoreTests cover missing object, partial object, clamping, unknown theme, round-trip.
- `37-2-missing` an existing settings file without `terminal` launches with the Terminal off and is rewritten with defaults on the next write.
- `37-2-odd-values` `fontSize: 99` and `theme: "neon"` keep the rest of the file (no `settings.corrupt-*.json`).

## How to get to it (user POV)

- Upgrade from a Slotbar version without the Terminal: the existing file has no `terminal` key.

## Driving it with slotbar-verify and orca computer

Preconditions: built app.

- **Unit tests.** Run `swift test --filter SettingsStoreTests`. All pass.
- **Missing object.** `V launch`, then `plutil -remove terminal "<run>/home/Library/Application Support/Slotbar/settings.json"`, `V relaunch`, `V show`. The Rail has no Terminal button (`oc get-app-state --query Terminal` finds none), both Slots are there. Click `Settings`, toggle "Enable Terminal" on: `V settings` shows `terminal` with `enabled true, fontSize 13, theme system, shellPath null, startDirectory null`, `schemaVersion` 1.
- **Odd values.** Set `fontSize` 99 and `theme` "neon" with `plutil -replace`, `V relaunch`. Process alive, no `settings.corrupt-*` file in the settings directory, Slots intact. Turn the Terminal on in Settings: `V settings` shows `fontSize` 36 and `theme` "system".
- **Proof.** `V settings` before/after into `<run>/evidence/37-2-*.json`, `ls` of the settings directory.

## Gotchas

- `V launch` always seeds a `terminal` object; the "missing" case needs the manual `plutil` edit plus `V relaunch`.
- Clamped/defaulted values are written back only on the next settings write; toggle something to observe them in the file.
