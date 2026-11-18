# Tab bar only with two or more tabs (#41, criterion 1)

The tab bar appears only with two or more tabs; a single tab uses all the space.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence

## Sub-features

- `41-1-single` one tab: no tab bar, terminal fills the content area.
- `41-1-two` second tab: tab bar appears.
- `41-1-back` closing back to one: tab bar disappears and the terminal grows.

## How to get to it (user POV)

- `Cmd+T` and `Cmd+W` in the Terminal.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Single.** Type `stty size > ~/size1` + Return; `V shot 41-1-single`: no tab strip.
- **Two.** `oc hotkey --key CmdOrCtrl+T`. `V shot 41-1-two`: tab strip with two tabs; `oc get-app-state` lists two tab elements (AX buttons labelled with the tab title; an untitled tab shows its shell's name, e.g. `zsh`).
- **Back.** `oc hotkey --key CmdOrCtrl+W`. Strip gone; type `stty size > ~/size2`: equals `size1`.

## Gotchas

- The bar is 28 pt high at the top of the Terminal area; with one tab it is removed from the view tree, not hidden.
- `stty size` proves the space is reclaimed; a screenshot alone can miss a hidden-but-reserved strip.
