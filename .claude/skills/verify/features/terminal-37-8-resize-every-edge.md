# Rows and columns follow Panel resize on every edge (#37, criterion 8)

Resizing the Panel changes the Terminal's rows and columns, so full-screen programs redraw; this holds with the Panel on the left, right, top and bottom edges.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence

## Sub-features

- `37-8-right`, `37-8-left`, `37-8-top`, `37-8-bottom` resize on each edge changes `stty size`.
- `37-8-redraw` a full-screen program (`top`) redraws to the new size.

## How to get to it (user POV)

- Drag the Panel's resize handle (inner edge); change Panel edge in Settings > General.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal --edge <edge>` per edge, `V show`, click `Terminal`.

- **Before.** Type `stty size > ~/size-before` + Return.
- **Resize.** Drag the resize handle: `oc drag --from-x <handle> --from-y <mid> --to-x <handle-200> --to-y <mid>` (coordinates from `V doctor` window bounds; the handle is the Panel side facing the screen centre).
- **After.** Type `stty size > ~/size-after` + Return. The two files differ in the resized dimension (columns for left/right, rows for top/bottom).
- **Redraw.** Type `top` + Return, resize again, `V shot 37-8-<edge>-top`: top fills the Panel with no garbage; `q` to quit.
- **Edges.** Repeat with `--edge left`, `top`, `bottom` (or change Panel edge in Settings > General and `V show`).

## Gotchas

- Background `oc drag` on the handle resizes the Panel, but the resulting depth does not track the drag distance (sometimes it grows when dragged inward); prove the criterion with `stty size` before and after a drag that changed the frame in `V doctor`, not with a target width.
- Panel depth is saved to settings on resize. A Panel edge changed in Settings > General applies on the next show: `Cmd+1`, `Cmd+W`, `V show`, then click `Terminal`.
