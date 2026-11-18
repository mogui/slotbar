# Slotbar Terminal verification map

One file per acceptance criterion of the Terminal tickets (spec `docs/terminal-spec.md`, issues mogui/slotbar#37 and #39-#46). Read this index, then the feature file, then drive. #38 (this skill) and #47 (docs only) have no feature files.

## File names and status

- `terminal-<issue>-<k>-<slug>.md`: `<k>` is the criterion's position in the issue's "Acceptance criteria" list, counted from 1.
- Each file has a `Status:` line under its title: `pending` (never driven live), or `passed <date> <evidence dir>` / `failed <date> <evidence dir> - <reason>` after a live run. Only a live run through the recipe changes it. A note after the evidence dir names sub-features that ran elsewhere or were not driven; `user-reported` marks a step the user performed and reported (global hotkeys, hover, system appearance, Option keys) with no recorded artifact.

## Baseline preconditions

- `V` = `.claude/skills/verify/scripts/slotbar-verify`; `oc <action>` = `orca computer <action> --app io.github.mogui.slotbar.verify --json`.
- Build first (`V build`), then `V launch --terminal` unless the recipe says otherwise, `V show`, `V doctor` (after the show: Accessibility is read through the Panel). Doctor must show the process alive, revision = worktree HEAD, one layer-3 window, `accessibility: ok`.
- Seeded state: Profile "Verify", Slot 1 "Example" (https://example.com), Slot 2 "Example Org" (https://example.org), Panel on the right edge, hide on focus loss off.
- The isolated home is `<run>/home` (`<run>` from `V doctor`); new shells start there.
- Never drive the user's own Slotbar (`/Applications/Slotbar.app`, bundle id `io.github.mogui.slotbar`).

## Driving conventions

- Enter the Terminal by clicking its Rail button: in `oc get-app-state` the first unnamed `button` after the `button Globe` Slot buttons (`button Terminal, bell` while a tab is flagged), then `oc click --element-index <i>`. Tooltips are not in the tree; reading one is a user step (hover).
- Type in a tab with `oc type-text --text '<cmd>'` + `oc press-key --key Return`. Results come back `unverified (text mismatch)` because the terminal view has no text field: prove the effect with `V shot` or a file the command writes under `<run>/home`.
- Make proofs observable outside the pixels when possible: commands that write to `<run>/home/<file>`, `V shells` (pid, `-zsh`, tty, cwd), `V settings`, `V logs` (category `Terminal`).
- One action, then a shot: `V shot <feature>-<step>`.
- `V stop` after each session; evidence stays in `<run>/evidence/`.

## Proof and skip reporting

- A criterion passes only when its "Driving it" steps ran on the live app and the stated end state was observed. Unit-test criteria name the suite and the `swift test --filter` output.
- A step that cannot run (no Accessibility, a global hotkey the harness cannot send, a system dialog) is reported as "not driven" with the reason; never as passed through another path.

## Features

### #37 Terminal skeleton
- [terminal-37-1-swiftterm-dependency](terminal-37-1-swiftterm-dependency.md)
- [terminal-37-2-settings-terminal-object](terminal-37-2-settings-terminal-object.md)
- [terminal-37-3-settings-enable-toggle](terminal-37-3-settings-enable-toggle.md)
- [terminal-37-4-rail-terminal-item](terminal-37-4-rail-terminal-item.md)
- [terminal-37-5-login-shell](terminal-37-5-login-shell.md)
- [terminal-37-6-first-responder](terminal-37-6-first-responder.md)
- [terminal-37-7-active-view-cmd-digits](terminal-37-7-active-view-cmd-digits.md)
- [terminal-37-8-resize-every-edge](terminal-37-8-resize-every-edge.md)
- [terminal-37-9-controller-lifetime](terminal-37-9-controller-lifetime.md)
- [terminal-37-10-turn-off-falls-back-slot1](terminal-37-10-turn-off-falls-back-slot1.md)
- [terminal-37-11-relaunch-fresh-tab](terminal-37-11-relaunch-fresh-tab.md)

### #39 Terminal hotkey
- [terminal-39-1-hotkey-registration](terminal-39-1-hotkey-registration.md)
- [terminal-39-2-hidden-shows-terminal](terminal-39-2-hidden-shows-terminal.md)
- [terminal-39-3-switch-from-slot-or-settings](terminal-39-3-switch-from-slot-or-settings.md)
- [terminal-39-4-shown-not-key-makes-key](terminal-39-4-shown-not-key-makes-key.md)
- [terminal-39-5-shown-and-key-hides](terminal-39-5-shown-and-key-hides.md)
- [terminal-39-6-settings-recorder](terminal-39-6-settings-recorder.md)
- [terminal-39-7-rail-tooltip-hotkey](terminal-39-7-rail-tooltip-hotkey.md)
- [terminal-39-8-panel-hotkey-last-view](terminal-39-8-panel-hotkey-last-view.md)
- [terminal-39-9-toggle-tests](terminal-39-9-toggle-tests.md)

### #40 Terminal tabs: session model and keyboard
- [terminal-40-1-session-model](terminal-40-1-session-model.md)
- [terminal-40-2-new-and-switch-tabs](terminal-40-2-new-and-switch-tabs.md)
- [terminal-40-3-cmd-w-close](terminal-40-3-cmd-w-close.md)
- [terminal-40-4-shell-exit-closes](terminal-40-4-shell-exit-closes.md)
- [terminal-40-5-busy-close-confirm](terminal-40-5-busy-close-confirm.md)
- [terminal-40-6-tab-titles-focus](terminal-40-6-tab-titles-focus.md)
- [terminal-40-7-terminal-shortcut-mappings](terminal-40-7-terminal-shortcut-mappings.md)
- [terminal-40-8-slot-mappings-unchanged](terminal-40-8-slot-mappings-unchanged.md)
- [terminal-40-9-model-and-mapping-tests](terminal-40-9-model-and-mapping-tests.md)

### #41 Terminal tab bar
- [terminal-41-1-bar-visibility](terminal-41-1-bar-visibility.md)
- [terminal-41-2-titles-click-select](terminal-41-2-titles-click-select.md)
- [terminal-41-3-hover-close](terminal-41-3-hover-close.md)
- [terminal-41-4-double-click-new-tab](terminal-41-4-double-click-new-tab.md)

### #42 Busy-tab confirmation on turn-off and Quit
- [terminal-42-1-turn-off-confirm](terminal-42-1-turn-off-confirm.md)
- [terminal-42-2-quit-confirm](terminal-42-2-quit-confirm.md)
- [terminal-42-3-idle-no-confirm](terminal-42-3-idle-no-confirm.md)
- [terminal-42-4-turned-off-event-tests](terminal-42-4-turned-off-event-tests.md)

### #43 Themes and font size
- [terminal-43-1-palettes-system-live](terminal-43-1-palettes-system-live.md)
- [terminal-43-2-cursor-scrollback](terminal-43-2-cursor-scrollback.md)
- [terminal-43-3-theme-font-settings](terminal-43-3-theme-font-settings.md)
- [terminal-43-4-font-size-keys](terminal-43-4-font-size-keys.md)

### #44 Shell and starting directory settings
- [terminal-44-1-shell-dir-fields](terminal-44-1-shell-dir-fields.md)
- [terminal-44-2-null-defaults-tilde](terminal-44-2-null-defaults-tilde.md)
- [terminal-44-3-new-tabs-only](terminal-44-3-new-tabs-only.md)
- [terminal-44-4-start-failure-retry](terminal-44-4-start-failure-retry.md)

### #45 Clipboard, keyboard and links
- [terminal-45-1-copy](terminal-45-1-copy.md)
- [terminal-45-2-paste-bracketed](terminal-45-2-paste-bracketed.md)
- [terminal-45-3-select-all](terminal-45-3-select-all.md)
- [terminal-45-4-clear](terminal-45-4-clear.md)
- [terminal-45-5-option-composes](terminal-45-5-option-composes.md)
- [terminal-45-6-cmd-click-url](terminal-45-6-cmd-click-url.md)

### #46 Bell dot
- [terminal-46-1-bell-flag-model](terminal-46-1-bell-flag-model.md)
- [terminal-46-2-tab-dot](terminal-46-2-tab-dot.md)
- [terminal-46-3-rail-dot](terminal-46-3-rail-dot.md)
- [terminal-46-4-no-notification](terminal-46-4-no-notification.md)
