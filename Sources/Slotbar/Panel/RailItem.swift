import Foundation

/// What the Rail shows for one Slot (SPEC 4.4).
struct RailItem: Equatable {
    var slotId: UUID
    var tooltip: String
    var color: ProfileColor
    var isActive: Bool
}

/// One item per Slot in list order. Tooltip: label (Home host while null), plus `⌘N` for the first nine.
func railItems(settings: Settings, activeSlot: UUID?) -> [RailItem] {
    settings.slots.enumerated().map { index, slot in
        let name = slot.label ?? slot.url.host() ?? slot.url.absoluteString
        let color = settings.profiles.first { $0.id == slot.profileId }?.color ?? ""
        return RailItem(slotId: slot.id,
                        tooltip: index < 9 ? "\(name)  ⌘\(index + 1)" : name,
                        color: ProfileColor(hex: color),
                        isActive: slot.id == activeSlot)
    }
}
