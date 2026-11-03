import Foundation

/// What a loaded Slot reports to the badge (SPEC 8.4).
enum UnreadState: Equatable {
    case none
    case count(Int)
    /// Unread exists, number not known: shown as a dot.
    case unknown
}

/// One loaded Slot's input to the aggregation.
struct SlotUnread: Equatable {
    var profileId: UUID
    var homeHost: String
    var state: UnreadState
}

/// Total unread count plus whether any Slot is "count unknown".
struct Badge: Equatable {
    var count: Int
    var dot: Bool
}

extension Badge {
    /// One Slot's own badge, used by the Rail.
    init(_ state: UnreadState) {
        switch state {
        case .none: self.init(count: 0, dot: false)
        case .count(let n): self.init(count: n, dot: false)
        case .unknown: self.init(count: 0, dot: true)
        }
    }
}

enum BadgeAggregator {
    /// Max per (Profile, Home host), summed; dot when any Slot is unknown. Pass loaded Slots only.
    static func aggregate(_ slots: [SlotUnread]) -> Badge {
        var maxByGroup: [String: Int] = [:]
        var dot = false
        for slot in slots {
            switch slot.state {
            case .none: break
            case .unknown: dot = true
            case .count(let n):
                let key = "\(slot.profileId.uuidString)|\(slot.homeHost)"
                maxByGroup[key] = max(maxByGroup[key] ?? 0, n)
            }
        }
        return Badge(count: maxByGroup.values.reduce(0, +), dot: dot)
    }
}

/// Status item and Rail text: `1`...`99`, `99+`, then `●` when a dot applies; nil when nothing is unread.
func badgeText(_ badge: Badge) -> String? {
    let digits = badge.count == 0 ? "" : badge.count > 99 ? "99+" : String(badge.count)
    let text = digits + (badge.dot ? "\u{25CF}" : "")
    return text.isEmpty ? nil : text
}
