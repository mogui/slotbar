# Turning off with busy tabs asks once (#42, criterion 1)

Turning the Terminal off with any busy tab asks one confirmation listing the busy tabs' titles; confirm terminates all shells; cancel keeps the Terminal on.

Status: pending

## Sub-features

- `42-1-ask` one dialog naming each busy tab's title.
- `42-1-cancel` cancel: toggle back on, `enabled` true in settings, shells alive.
- `42-1-confirm` confirm: all shells gone, `enabled` false.

## How to get to it (user POV)

- Settings > Terminal > Enable Terminal off while something runs.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Busy tabs.** Type `printf '\e]0;BUSY-A\a'; sleep 602` + Return; `Cmd+T`, `printf '\e]0;BUSY-B\a'; sleep 603` + Return; `Cmd+T` (idle third tab).
- **Ask.** Click `Settings`, click "Enable Terminal". One dialog; its text contains `BUSY-A` and `BUSY-B` and not the idle tab. `V shot 42-1-ask`.
- **Cancel.** Click cancel. `V settings`: `enabled` true; the switch shows on; `pgrep -f "sleep 60[23]"` finds both.
- **Confirm.** Toggle again, confirm. `V settings`: false; `V shells` empty; no `sleep 602/603`.

## Gotchas

- A title set by `printf` is overwritten by `sleep` if the shell theme sets titles on preexec; then expect the command name (`sleep`) as the title.
