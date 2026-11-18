# Shell and directory changes apply to new tabs only (#44, criterion 3)

Changing shell or starting directory affects tabs spawned afterwards; running tabs keep their shell and directory.

Status: pending

## Sub-features

- `44-3-existing` the open tab keeps its pid, shell and cwd.
- `44-3-new` a new tab uses the new settings.

## How to get to it (user POV)

- Change the fields, then `Cmd+T`.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `V shells` saved as `before`.

- **Change.** Settings: shell `/bin/bash`, directory `/tmp`.
- **Existing.** Click `Terminal`; `V shells`: original pid still `-zsh`, same cwd.
- **New.** `Cmd+T`; `V shells`: a new `-bash` with `cwd=/private/tmp`.

## Gotchas

- `/bin/bash` prints the "default interactive shell is now zsh" banner; harmless.
- `Cmd+T` exists only once #40 (tabs) is merged. Before that, spawn a new shell by typing `exit` in the tab after 2 s (respawns with the current settings) or by turning the Terminal off and on.
