import Foundation

/// View made visible on show: the last active one if it still exists (a Slot in the list, or the Terminal
/// while enabled), else Slot 1 (SPEC 4.5).
func viewToShow(slots: [Slot], lastActive: PanelView?, terminalEnabled: Bool) -> PanelView? {
    switch lastActive {
    case .terminal where terminalEnabled: return .terminal
    case .slot(let id) where slots.contains(where: { $0.id == id }): return lastActive
    default: return slots.first.map { .slot($0.id) }
    }
}

/// Kept-alive Slots load in the background at launch, in list order (SPEC 6.2).
func slotsLoadedAtLaunch(_ slots: [Slot]) -> [UUID] {
    slots.filter(\.keepAlive).map(\.id)
}

/// Slot N for `Cmd+N` (1-based); `nil` when there is no Slot N (SPEC 9).
func slotId(number: Int, in slots: [Slot]) -> UUID? {
    slots.indices.contains(number - 1) ? slots[number - 1].id : nil
}
