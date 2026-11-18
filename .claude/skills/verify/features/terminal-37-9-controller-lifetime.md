# Terminal controller lifetime (#37, criterion 9)

The Terminal is created on enable and destroyed with its shells terminated on disable; Slot lifecycle and memory pressure never unload it; shells keep running while the Panel is hidden.

Status: pending

## Sub-features

- `37-9-create` enable spawns one shell (`V shells`, log `Spawning`).
- `37-9-destroy` disable terminates it (no child shell left).
- `37-9-hidden` a loop keeps writing while the Panel is hidden.
- `37-9-slot-lifecycle` Slot unload/grace periods do not touch the shell.
- `37-9-memory` a memory-pressure event leaves the shell running.

## How to get to it (user POV)

- Settings toggle; hide the Panel with `Cmd+W` or the hotkey and come back later.

## Driving it with slotbar-verify and orca computer

Preconditions: `V launch` (off), `V show`.

- **Create.** Settings > Enable Terminal on. `V shells`: one `-zsh`; `V logs`: `Spawning`.
- **Hidden.** Click `Terminal`, type `while true; do date >> ~/tick; sleep 1; done` + Return, `oc hotkey --key CmdOrCtrl+W`. `V doctor` shows no window; after 10 s `wc -l <run>/home/tick` keeps growing; the shell pid is unchanged.
- **Memory pressure.** With the user's consent only: `memory_pressure -S -l warn` (simulated pressure, sudo not needed for -S on recent macOS; if it asks for sudo, mark not driven). `V logs` shows `Memory pressure`; `V shells` pid unchanged; tick still grows.
- **Destroy.** `V show`, Settings > Enable Terminal off. `V shells` empty; tick stops growing.

## Gotchas

- `memory_pressure` affects the whole Mac; never run it without asking the user.
- Slot lifecycle grace periods are minutes long; the Slot-lifecycle sub-feature is covered by code reading plus SlotLifecycleTests unless the run waits for the grace period.
