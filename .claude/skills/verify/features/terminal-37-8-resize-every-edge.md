# Rows and columns follow Panel resize on every edge (#37, criterion 8)

Resizing the Panel changes the Terminal's rows and columns, so full-screen programs redraw; this holds with the Panel on the left, right, top and bottom edges.

Status: pending

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

- Drags in background may be ignored by AppKit resize handles; if the window frame in `V doctor` does not change, the drag needs `--restore-window` (ask the user).
- Panel depth is saved to settings on resize; each edge run starts from the seed, so use a new `V launch` per edge.
