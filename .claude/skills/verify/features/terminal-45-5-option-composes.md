# Option composes characters (#45, criterion 5)

Option composes characters as in macOS (e.g. `@`, `#`, `[`, `]` on an Italian layout); it is not a Meta key.

Status: pending

## Sub-features

- `45-5-italian` on the Italian layout, `Option+ò` gives `@`, `Option+à` gives `#`, `Option+è` / `Option+Shift+è` give `[` / `]`.
- `45-5-no-meta` `Option+B` does not move back a word in zsh (no ESC-b sent); it types the composed character.

## How to get to it (user POV)

- Type with Option on an Italian keyboard.

## Driving it with slotbar-verify and orca computer

Preconditions: the Italian input source is active (ask the user to switch, or confirm it already is); `V launch --terminal`, `V show`, click `Terminal`.

- **Compose.** Type `cat > ~/opt.txt` + Return; send `oc hotkey --key Alt+ò`, `Alt+à`, `Alt+è`, `Alt+Shift+è`, then `Control+D`. `~/opt.txt` is `@#[]`.
- **No Meta.** At the prompt type `abc`, `oc hotkey --key Alt+B`: the line shows `abc∫` (US) or the layout's character, cursor not moved.

## Gotchas

- Synthetic key events carry key codes; the composed character depends on the active input source. The user's layout must be Italian for this recipe; never switch the input source without asking.
- If `oc hotkey` cannot name `ò`/`à`/`è`, use their key codes per `oc hotkey --help`, or ask the user to type them.
- Built: `optionAsMetaKey = false` per tab (SwiftTerm defaults to true). `Option+Left/Right` still move by word: SwiftTerm applies the macOS Option-arrow bindings regardless.
