# Login shell in the Terminal (#37, criterion 5)

Clicking the Terminal item shows one tab running the login shell (argv[0] prefixed with `-`) from `$SHELL` in the home directory, with the app environment plus `TERM=xterm-256color`, in SF Mono at the settings size.

Status: pending

## Sub-features

- `37-5-one-tab` one shell process, no tab bar.
- `37-5-login` argv[0] `-zsh` (or `-<basename $SHELL>`).
- `37-5-home` cwd is the home directory.
- `37-5-term` `echo $TERM` prints `xterm-256color`; `echo $PATH` shows the login profile's PATH.
- `37-5-font` SF Mono at `fontSize` (13 by default).

## How to get to it (user POV)

- Turn the Terminal on, click the Rail Terminal icon.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Open.** Click `Terminal`. `V shot 37-5-open` shows a prompt.
- **Process.** `V shells`: exactly one line, `argv=-zsh`, `cwd=<run>/home`.
- **Environment.** Type `echo $TERM $0; pwd > ~/pwd.txt; echo $TERM > ~/term.txt` + Return. `cat <run>/home/term.txt` is `xterm-256color`; `<run>/home/pwd.txt` is `<run>/home`.
- **Font.** `V shot 37-5-font`: monospaced SF Mono glyphs (slashed zero, SF Mono `@`).
- **Proof.** shots, `V shells` output, the two files.

## Gotchas

- Home is the isolated `<run>/home` (the app runs with `CFFIXED_USER_HOME`), not the user's home; the shell still loads the user's real `~/.zshrc` because `HOME` is inherited unchanged. Expected; do not "fix" it.
- `ps` cannot show another process's environment on macOS; TERM is proven only from inside the shell.
- The verify copy is launched by `open`, so `$SHELL` comes from launchd's environment.
