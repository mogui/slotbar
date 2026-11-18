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
- **Ask.** Click `Settings`, click "Enable Terminal". One app-modal alert "Terminate running processes?", buttons `Terminate` / `Cancel`; its text lists `BUSY-A` and `BUSY-B` (one per line) and not the idle tab. `V shot 42-1-ask`.
- **Cancel.** Click `Cancel` (or Escape). `V settings`: `enabled` true; the switch shows on; `pgrep -f "sleep 60[23]"` finds both.
- **Confirm.** Toggle again, click `Terminate`. `V settings`: false; `V shells` empty; no `sleep 602/603`.

## Gotchas

- A title set by `printf` is overwritten by `sleep` if the shell theme sets titles on preexec; then expect the command name (`sleep`) as the title.
- A busy tab whose shell set no title is listed by its shell name (basename of the spawned shell, e.g. `zsh`).
- Editing `settings.json` by hand is read only at launch: `enabled: false` written to the file changes nothing live (and the next Settings write overwrites it); it takes effect after `V relaunch`, with no confirmation.
- The alert is app-modal (`runModal`), not a sheet: `V doctor` lists it as a separate window.
- Only the Settings toggle asks. Writing `enabled: false` into settings.json terminates the shells without asking.
