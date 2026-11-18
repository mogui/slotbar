# Tab titles and click to select (#41, criterion 2)

Each tab in the bar shows its title; clicking a tab selects it.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `41-2-title` a title set with OSC 0 shows in the tab.
- `41-2-click` clicking an inactive tab selects it and focuses its shell.

## How to get to it (user POV)

- Look at and click the tab bar.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T` (two tabs).

- **Titles.** In tab 2 type `printf '\e]0;TAB-TWO\a'` + Return; `Cmd+Shift+[`, type `printf '\e]0;TAB-ONE\a'` + Return. `oc get-app-state --query TAB-` finds both; `V shot 41-2-titles`.
- **Click.** Click the `TAB-TWO` element (AX button; AX press also selects). Type `tty > ~/clicked` + Return: its tty is tab 2's shell (`V shells`).

## Gotchas

- An untitled tab shows the basename of its own shell (`zsh`), not the current Settings shell.
- The active tab has AX selected = true and the control background; inactive titles are secondary-colored.
- zsh themes may overwrite the title at every prompt; if the title flips back, run with `DISABLE_AUTO_TITLE=true` or `precmd_functions=()` first.
