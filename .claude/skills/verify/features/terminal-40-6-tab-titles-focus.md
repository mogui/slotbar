# Tab titles and focus on switch (#40, criterion 6)

Each tab's title is the title its shell sets (OSC 0/2); the active tab becomes first responder on show and on tab switch.

Status: pending

## Sub-features

- `40-6-title` `printf '\e]0;VERIFY-TITLE\a'` sets the tab title.
- `40-6-focus-switch` after `Cmd+Shift+]` keys reach the newly active tab.
- `40-6-focus-show` after hide/show keys reach the active tab.

## How to get to it (user POV)

- Run commands that set the title (zsh prompt themes, ssh, vim).

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Title.** `Cmd+T` (tab bar appears with #41), type `printf '\e]0;VERIFY-TITLE\a'` + Return. `oc get-app-state --query VERIFY-TITLE` finds the tab; `V shot 40-6-title`.
- **Focus on switch.** `Cmd+Shift+[`, type `touch ~/focus-switch` + Return: file exists; `tty` written to a file matches the first shell.
- **Focus on show.** Leave with `Cmd+1`, then click `Terminal`; type `touch ~/focus-show`: exists.

## Gotchas

- The first responder is set by `PanelController.activate` (show) and `TerminalController.showActiveTab` (switch); a tab title is "" until the shell sets one.
- Before #41 there is no tab bar to read titles from; verify titles once #41 is merged, or through the model tests.
- `oc type-text` on the terminal view reports `unverified (text mismatch)`; prove with shots, `V shells` and files under `<run>/home`.
