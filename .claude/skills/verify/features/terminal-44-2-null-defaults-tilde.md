# Null shell, null directory and ~ expansion (#44, criterion 2)

`shellPath` null uses `$SHELL`; `startDirectory` null uses home; a leading `~` expands to home.

Status: pending

## Sub-features

- `44-2-null-shell` argv `-zsh` from `$SHELL`.
- `44-2-null-dir` cwd = home.
- `44-2-tilde` `~/work` opens in `<home>/work`.

## How to get to it (user POV)

- Leave the fields empty, or type a `~` path.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `mkdir -p <run>/home/work`, `V show`, click `Terminal`.

- **Nulls.** `V shells`: `argv=-zsh`, `cwd=<run>/home`.
- **Tilde.** Settings > directory `~/work`; `Cmd+T` in the Terminal. `V shells`: new shell `cwd=<run>/home/work`.
- **Unit.** `swift test --filter ShellLaunchTests`.

## Gotchas

- Home is the isolated `<run>/home` (CFFIXED_USER_HOME), so `~` expands there, not to the user's home.
- `Cmd+T` exists only once #40 (tabs) is merged. Before that, spawn a new shell by typing `exit` in the tab after 2 s (respawns with the current settings) or by turning the Terminal off and on.
