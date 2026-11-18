# Cmd+K clears screen and scrollback (#45, criterion 4)

`Cmd+K` clears the screen and the scrollback of the current tab only.

Status: pending

## Sub-features

- `45-4-current` current tab: no previous output above the prompt, scrolling up shows nothing.
- `45-4-other` another tab keeps its output.

## How to get to it (user POV)

- `Cmd+K` in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Fill.** Type `seq 1 500` + Return; `Cmd+T`, `echo OTHER-TAB` + Return; `Cmd+Shift+[`.
- **Clear.** `oc hotkey --key CmdOrCtrl+K`. `V shot 45-4-after`: only a prompt; `oc scroll --direction up --pages 20`: still nothing.
- **Other tab.** `Cmd+Shift+]`: `OTHER-TAB` still visible.
- **Shell intact.** Type `echo $$`: same pid as before (`V shells`).

## Gotchas

- `Cmd+K` must not send `clear` to the shell; the shell's history is untouched.
- Built: the view gets `ESC[3J ESC[2J ESC[H` (local clear), then Ctrl+L (0x0C) goes to the shell only when the tab is not busy, so zsh redraws its prompt (typed text kept). While a program runs (e.g. `sleep 30`, `less`) the clear is local only: blank screen, nothing sent.
- A tab showing the start-failure screen gets the local clear only.
