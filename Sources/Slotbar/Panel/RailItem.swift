import Foundation

/// What the Panel shows in its content area: a Slot or the Terminal.
enum PanelView: Hashable {
    case slot(UUID)
    case terminal
}

/// What the Rail shows for one Slot (SPEC 4.4) or for the Terminal.
struct RailItem: Equatable {
    var view: PanelView
    var tooltip: String
    /// The Slot's Profile color bar; nil for the Terminal.
    var color: ProfileColor?
    var isActive: Bool
    var notifications: Bool
    /// The Slot's own badge text (SPEC 8.4); nil when nothing is unread or the Slot is Unloaded.
    var badge: String? = nil
    /// The Terminal item's bell dot: some Terminal tab rang the bell while not visible.
    var bell = false
}

/// One item per Slot in list order, then the Terminal while it is enabled.
/// Slot tooltip: label (Home host while null), plus `⌘N` for the first nine. `unread` holds loaded Slots only.
/// Terminal tooltip: "Terminal" plus `terminalHotkey` when one is set.
func railItems(settings: Settings, activeView: PanelView?, unread: [UUID: UnreadState] = [:],
               terminalHotkey: String? = nil, terminalBell: Bool = false) -> [RailItem] {
    var items = settings.slots.enumerated().map { index, slot in
        let name = slot.label ?? slot.url.host() ?? slot.url.absoluteString
        let color = settings.profiles.first { $0.id == slot.profileId }?.color ?? ""
        return RailItem(view: .slot(slot.id),
                        tooltip: index < 9 ? "\(name)  ⌘\(index + 1)" : name,
                        color: ProfileColor(hex: color),
                        isActive: activeView == .slot(slot.id),
                        notifications: slot.notifications,
                        badge: unread[slot.id].flatMap { badgeText(Badge($0)) })
    }
    if settings.terminal.enabled {
        items.append(RailItem(view: .terminal, tooltip: terminalHotkey.map { "Terminal  \($0)" } ?? "Terminal", color: nil,
                              isActive: activeView == .terminal, notifications: false, bell: terminalBell))
    }
    return items
}
