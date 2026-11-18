# SwiftTerm dependency (#37, criterion 1)

SwiftTerm is the second SwiftPM dependency and the Slotbar target stays in Swift 6 mode; the app builds and the Terminal renders with it.

Status: pending

## Sub-features

- `37-1-package` Package.swift lists exactly two dependencies: KeyboardShortcuts and SwiftTerm.
- `37-1-swift6` the Slotbar target uses Swift 6 language mode.
- `37-1-builds` `V build` and `swift test` succeed.

## How to get to it (user POV)

- Not user-visible; a developer builds the app.

## Driving it with slotbar-verify and orca computer

Preconditions: clean worktree.

- **Dependencies.** Run `swift package show-dependencies --format json`. Top-level dependencies are `KeyboardShortcuts` and `SwiftTerm` only.
- **Language mode.** Run `grep -n "swiftLanguageMode\|swift-tools-version\|swiftLanguageVersions" Package.swift`. Tools version 6.x with no Swift 5 override on the Slotbar target.
- **Build.** Run `V build`. Ends with `Built build/Slotbar.app (debug)`.
- **Tests.** Run `swift test`. Exit code 0.
- **Proof.** Save the three outputs to `<run>/evidence/37-1-*.txt`.

## Gotchas

- `swift build` alone uses the native build system; the app bundle is only valid from `scripts/build-app.sh` (Swift Build), which `V build` calls.
