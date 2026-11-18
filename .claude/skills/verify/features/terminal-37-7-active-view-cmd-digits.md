# Active view and Cmd+1..9 from the Terminal (#37, criterion 7)

The Panel's active view is either a Slot or the Terminal; with the Terminal active, `Cmd+1..9` switches to that Slot.

Status: pending

## Sub-features

- `37-7-exclusive` showing the Terminal hides the Slot's webview and vice versa.
- `37-7-cmd-digit` `Cmd+2` from the Terminal shows Slot 2; `Cmd+1` shows Slot 1.
- `37-7-guards` `Cmd+R`, `Cmd+Shift+H`, `Cmd+Shift+O` on the Terminal do nothing to the hidden Slot.

## How to get to it (user POV)

- Click the Terminal icon, press `Cmd+2`.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`.

- **Terminal active.** Click `Terminal`. `V shot 37-7-terminal`: shell visible, no web page; Rail highlight on Terminal.
- **Cmd+2.** `oc hotkey --key CmdOrCtrl+2`. `V shot 37-7-slot2`: example.org page, highlight on `Example Org`.
- **Back and Cmd+1.** Click `Terminal`, `oc hotkey --key CmdOrCtrl+1`: example.com page.
- **Guards.** Click `Terminal`, press `CmdOrCtrl+Shift+O`: no browser opens (no new app in `oc list-apps` front); `CmdOrCtrl+R`: `V logs` shows no Slot reload line.
- **Proof.** shots per step.

## Gotchas

- `Cmd+Shift+O` would open the user's default browser if the guard failed; tell the user before running it.
- Slots load example.com/example.org on first show: network needed; wait for the page (`oc wait --text "Example Domain"`).
