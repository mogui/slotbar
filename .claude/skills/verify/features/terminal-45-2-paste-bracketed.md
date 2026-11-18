# Cmd+V pastes with bracketed paste (#45, criterion 2)

`Cmd+V` pastes the clipboard; when the program enables bracketed paste (`\e[?2004h`), the text is wrapped in `\e[200~` ... `\e[201~`.

Status: pending

## Sub-features

- `45-2-plain` paste into `cat -v` without bracketed mode: raw text.
- `45-2-bracketed` with mode on: markers present; a multi-line paste in zsh does not run line by line.

## How to get to it (user POV)

- `Cmd+V` in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`; back up the clipboard (`pbpaste > <run>/clipboard.bak`).

- **Bracketed.** Type `printf '\e[?2004h'; cat -v > ~/paste.txt` + Return. `printf 'L1\nL2' | pbcopy`, `oc hotkey --key CmdOrCtrl+V`, `oc hotkey --key Control+D` twice. `~/paste.txt` contains `^[[200~L1` and `L2^[[201~`.
- **zsh.** At the prompt paste `echo A\necho B`: nothing runs until Return (zsh enables bracketed paste itself); `V shot 45-2-zsh`.
- **Restore.** `pbcopy < <run>/clipboard.bak`.

## Gotchas

- Restore the user's clipboard after every paste test.
- Built: SwiftTerm's `paste:` via the hidden Edit menu; bracketed markers come from SwiftTerm when mode 2004 is on (no Slotbar code).
