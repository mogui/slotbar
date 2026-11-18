# Dot on the flagged tab (#46, criterion 2)

The flagged tab shows a dot in the tab bar until it becomes visible.

Status: pending

## Sub-features

- `46-2-dot` a bell in an inactive tab draws a dot on that tab.
- `46-2-clear` selecting it removes the dot.

## How to get to it (user POV)

- Look at the tab bar after a background tab rings.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`, `Cmd+T`.

- **Ring.** In tab 2 type `sleep 3; printf '\a'` + Return, then `Cmd+Shift+[` at once. After 4 s `V shot 46-2-dot`: accent dot right of tab 2's title; in `oc get-app-state` tab 2's button label reads `<title>, bell`.
- **Clear.** `Cmd+Shift+]`: `V shot 46-2-clear` without the dot; the AX label loses `, bell`.

## Gotchas

- The dot is drawn (no subview); the AX label suffix `, bell` is the non-visual proof.
- `printf '\a'` must run in the tab's own pty; `tput bel` works too. Do not ring from the harness shell.
