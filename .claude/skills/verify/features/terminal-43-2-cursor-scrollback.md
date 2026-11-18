# Blinking block cursor and 10,000 lines of scrollback (#43, criterion 2)

The cursor is a blinking block; each tab keeps 10,000 lines of scrollback.

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-143906/evidence

## Sub-features

- `43-2-cursor` block cursor that blinks.
- `43-2-scrollback` after `seq 1 12000`, the oldest reachable line is about 2001 (12000 - 10000 + visible rows).

## How to get to it (user POV)

- Look at the prompt; scroll up after long output.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch --terminal`, `V show`, click `Terminal`.

- **Cursor.** Two shots 300 ms apart (`V shot 43-2-c1`, `V shot 43-2-c2`): a filled block at the prompt in one, absent or hollow in the other.
- **Scrollback.** Type `seq 1 12000` + Return. Scroll to the top: `oc scroll --x <mid> --y <mid> --direction up --pages 400` (or `Cmd+Home` if the view supports it). `V shot 43-2-top`: first visible number is about 2000; never `1`.

## Gotchas

- Unfocused terminals may draw a hollow cursor; make the Panel key before the cursor shots.
