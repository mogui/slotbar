---
name: verify
description: Build, launch and drive the real Slotbar macOS menu bar app (Panel, Rail, Settings, Terminal) in an isolated copy, capturing screenshots, logs and process evidence. Use to prove a Slotbar change works the way a user sees it, or to verify an acceptance criterion from the feature map in features/.
---

# Verify Slotbar

Slotbar is an `LSUIElement` menu bar app: a status item opens the Panel (Rail of Slot icons, Terminal icon, gear; content area on the right). Verification drives an **isolated copy** of `build/Slotbar.app` and never the user's own Slotbar.

Tools:

- `.claude/skills/verify/scripts/slotbar-verify <command>` (below: `V`). Launch, doctor, show, screenshots, shell processes, logs, cleanup.
- `orca computer ... --app io.github.mogui.slotbar.verify` for clicks, keys and the accessibility tree. Load the `orca-computer-use` skill first (`orca skills get computer-use`). It needs the Accessibility permission for Orca Computer Use; `V doctor` reports `accessibility: DENIED` when it is missing. Without it, only screenshots, process checks, logs and settings reads are possible: report every criterion that needs input as "not driven: no Accessibility", never as passed.

## Isolation

- The copy lives in `/private/tmp/slotbar-verify/<run>/home/Applications/Slotbar.app` with bundle id `io.github.mogui.slotbar.verify`, so its UserDefaults (KeyboardShortcuts hotkeys), WebKit stores and notification identity are separate from the user's.
- It runs with `CFFIXED_USER_HOME=<run>/home`: settings are `<run>/home/Library/Application Support/Slotbar/settings.json`. The user's `~/Library/Application Support/Slotbar` is never read or written. It also sets `HOME=<run>/home`, which the Terminal's shells inherit: `~`, the starting directory, `~/.zshrc` (an empty one is created at launch) and the shell history all live in `<run>/home`, never in the user's home.
- Living under the isolated `~/Applications` keeps the modal "Move Slotbar to Applications" alert away; that alert blocks every reopen event.
- One live run at a time (`V launch` refuses a second). The user's production Slotbar (`/Applications/Slotbar.app`) may be running: never kill it, never drive it. It owns the global Panel hotkey, so the copy logs `Global hotkey registration failed`; that is expected, see the hotkey Gotchas.

## Launch

```sh
V=.claude/skills/verify/scripts/slotbar-verify
$V build                         # scripts/build-app.sh debug -> build/Slotbar.app
$V launch [--terminal] [--edge right|left|top|bottom]
```

`launch` seeds settings (Profile "Verify", Slot 1 "Example" = https://example.com, Slot 2 "Example Org" = https://example.org, both not Keep-alive; `hideOnFocusLoss` false so background driving does not hide the Panel; Terminal on with `--terminal`, else off) and waits for the app's `Launched` log line. It prints `ready pid=<pid> run=<dir>`. Rebuild before launching whenever the source changed: the copy is taken from `build/Slotbar.app`.

`$V relaunch` quits and restarts the same run (same settings, same home); for "after a relaunch" criteria.

## Doctor

`$V doctor`: run dir, build revision vs worktree HEAD, bundle id, process alive, settings path and `terminal.enabled`, on-screen windows (`id layer x y w h`), number of child shells, Accessibility status. Run it first and whenever something looks off. The Panel is the window at layer 3; no window means the Panel is hidden.

## Drive

- **Show the Panel:** `$V show` (a reopen event; the AppDelegate shows the Panel on the last active view, Slot 1 at first). No Accessibility needed.
- **Status item, hotkeys:** the status item is in the system menu bar, out of reach of `orca computer` (no menubar surface); use `$V show`. Global hotkeys (Panel, Terminal) cannot be sent by `orca computer hotkey` (it targets the app); see each feature's Gotchas.
- **Rail:** `orca computer get-app-state --app io.github.mogui.slotbar.verify --json`, then click the Rail button by element index. Buttons carry tooltips (`Example  ⌘1`, `Example Org  ⌘2`, `Terminal  ⌃⌥T`, `Settings`; two spaces before the shortcut), exposed as their help text; order top to bottom is Slots, Terminal, gear. Fallback when the tree shows no names: click by window-local coordinates from a fresh `V shot` (Rail is 34 pt buttons next to the screen edge; on the right edge it is the right-hand column).
- **Settings:** click the gear; one scrolling Form with sections General, Profiles, Slots, Terminal. The Terminal section has the toggle "Enable Terminal". Use `orca computer click` on the toggle, then confirm with `$V settings` (written immediately).
- **Terminal input:** with the Terminal shown and key, `orca computer type-text --app io.github.mogui.slotbar.verify --text 'echo $TERM' --json` then `press-key --key Return`. The terminal view has no text field: type results are `unverified (text mismatch)` by design; prove the effect with a screenshot.
- **Hide the Panel:** from a Slot, `Cmd+W`. While the Terminal is active `Cmd+W` closes the tab instead (on the last tab it also respawns the shell); to hide on the Terminal, the user presses `Ctrl+Option+T` (shown and key: hides), or switch to a Slot first (`Cmd+1`, `Cmd+W`; the next show then opens that Slot).
- **Clipboard:** the clipboard is the user's. `pbpaste > <run>/clipboard.bak` backs up text only, so ask the user before a clipboard test whether the clipboard holds anything else (an image, files).
- **Panel shortcuts:** `orca computer hotkey --app io.github.mogui.slotbar.verify --key CmdOrCtrl+1 --json` (and `Cmd+W`, `Cmd+T`, ...).
- **Processes:** `$V shells` lists each live shell: `pid`, `argv` (a login shell shows `-zsh`), `tty`, `cwd`.
- **Settings file:** `$V settings` prints the isolated `settings.json`.

## Evidence

Everything goes to `/private/tmp/slotbar-verify/<run>/evidence/` and survives `stop`:

- `$V shot <name>` saves `<name>-<windowid>.png` per on-screen Slotbar window (window-only capture; never full-screen, which would record the user's screen).
- `$V logs` writes `app.log` (unified log, subsystem `io.github.mogui.slotbar`, every process of the run) and prints it. Terminal events log under category `Terminal` (`Spawning /bin/zsh`; `Shell exited (<code>)`, followed by another `Spawning ...` only when the last tab respawns).
- `stop` also copies the final `settings.json`; `revision` holds the git sha that was built.

Proof standards:

- Drive the real user path (Rail click, Settings toggle, keys in the Panel). Seeding settings at launch is a precondition, never the proof of a Settings control.
- Capture the action and the resulting state: a shot before and after, plus `shells`/`settings`/`logs` for side effects.
- Name the feature file and the entry point next to each artifact in the report.
- A criterion covered only by unit tests (`swift test --filter <Suite>`) says so; it is not "driven live".

## Cleanup

`$V stop`: saves logs, terminates the process this run started (by its recorded pid, never by name; its shells exit with it), copies `settings.json` into evidence, deletes the app copy and isolated home, removes `/private/tmp/slotbar-verify/current`. Evidence stays in `<run>/evidence/`. Run `stop` after every failed attempt too.

## Feature map

`features/README.md` indexes one file per acceptance criterion of the Terminal tickets (`terminal-<issue>-<k>-<slug>.md`). Read the index, then the feature file, before driving.
