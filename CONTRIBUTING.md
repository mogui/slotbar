# Contributing to Slotbar

Bug reports, ideas and pull requests are welcome.

## Reporting a bug

Open an issue on [GitHub](https://github.com/mogui/slotbar/issues) with:

- Slotbar version (Settings or the DMG name) and macOS version
- Apple silicon or Intel
- The web app involved (Gmail, Calendar, Chat, other URL)
- Steps to reproduce, what you expected, what happened
- Screenshots or Console logs, if relevant

Do not paste cookies, tokens or anything from a signed-in session.

## Proposing a feature

Open an issue before writing code for anything beyond a small fix, so scope and design can be agreed first. New issues get the `needs-triage` label; an issue labelled `ready-for-human` or `ready-for-agent` is specified and open to be picked up.

## Development setup

Requirements: macOS 14 or later, Xcode with Swift 6.

```sh
git clone https://github.com/mogui/slotbar.git
cd slotbar
swift test                    # unit tests
scripts/build-app.sh debug    # build/Slotbar.app with the Web Inspector enabled
open build/Slotbar.app
```

Notifications only work when the app runs from `/Applications` or `~/Applications`. To test them, copy the debug build there.

## Project layout

| Path | Content |
|---|---|
| `Sources/Slotbar/` | App source |
| `Tests/SlotbarTests/` | Unit tests |
| `scripts/` | Build and release scripts |
| `GLOSSARY.md` | Domain vocabulary |
| `docs/SPEC.md` | Product specification |

## Vocabulary

Use the terms defined in [GLOSSARY.md](GLOSSARY.md) (Slot, Profile, Panel, Rail, ...) in code, tests, issues and commit messages.

## Pull requests

1. Fork the repo and create a branch from `main`.
2. Keep each PR focused on one change.
3. Add or update tests for logic changes.
4. Run `swift test` and check the change in a running app built with `scripts/build-app.sh debug`.
5. Update `README.md` when the change is visible to users.
6. Write commit messages as a short imperative summary of the change.
7. Reference the issue in the PR description (`Fixes #N`).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
