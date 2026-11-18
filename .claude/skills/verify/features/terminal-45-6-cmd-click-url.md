# Cmd-click on a URL opens the default browser (#45, criterion 6)

`Cmd`-click on a URL in the output opens it in the default browser through macOS, bypassing Slotbar's link routing (no Slot opens it).

Status: passed 2026-11-18 /private/tmp/slotbar-verify/20261118-141653/evidence; browser tab user-reported (observed by the user, no recorded artifact)

## Sub-features

- `45-6-open` the URL opens in the default browser.
- `45-6-no-route` no Slot loads it; the Panel stays on the Terminal.
- `45-6-plain-click` a click without Cmd opens nothing.

## How to get to it (user POV)

- Cmd-click a link in command output.

## Driving it with slotbar-verify and orca computer

Preconditions: user consent (a browser tab will open); `V launch --terminal`, `V show`, click `Terminal`, type `echo https://example.com/?verify=45-6` + Return.

- **Plain click.** `oc click --x <url x> --y <url y>`: no browser activity.
- **Cmd-click.** `oc click --x <url x> --y <url y> --modifiers CmdOrCtrl`. The default browser shows `example.com/?verify=45-6` (`oc get-app-state --app <browser> --query verify=45-6`). Slotbar: `V shot 45-6-after` still the Terminal; `V logs` has no route line.

## Gotchas

- Opens a tab in the user's browser: ask first and close it afterwards.
- Slot 1 is example.com too; the `verify=45-6` query string separates a routed load from the browser one.
- Built: SwiftTerm's default opener (no Slotbar override): `NSWorkspace` after its link-safety check. Holding Cmd while hovering underlines the link. Custom URL schemes show a confirmation first; unsafe local files are blocked. Plain URLs only, so use `https://`.
