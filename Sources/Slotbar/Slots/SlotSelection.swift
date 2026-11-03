import Foundation

/// Slot made visible on show: the last active one if it still exists, else Slot 1 (SPEC 4.5).
func slotToShow(slots: [Slot], lastActive: UUID?) -> UUID? {
    if let lastActive, slots.contains(where: { $0.id == lastActive }) { return lastActive }
    return slots.first?.id
}

/// Kept-alive Slots load in the background at launch, in list order (SPEC 6.2).
func slotsLoadedAtLaunch(_ slots: [Slot]) -> [UUID] {
    slots.filter(\.keepAlive).map(\.id)
}

/// Slot N for `Cmd+N` (1-based); `nil` when there is no Slot N (SPEC 9).
func slotId(number: Int, in slots: [Slot]) -> UUID? {
    slots.indices.contains(number - 1) ? slots[number - 1].id : nil
}
