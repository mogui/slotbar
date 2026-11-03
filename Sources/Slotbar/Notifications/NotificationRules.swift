import Foundation
import UserNotifications

/// Request identifier for a page notification (SPEC 8.2): `<Profile UUID>|<origin host>|<tag>` when the page
/// passes a tag (the same id replaces the earlier notification), else a random UUID. An empty tag is no tag.
func notificationRequestId(profileId: UUID, originHost: String, tag: String?, random: UUID = UUID()) -> String {
    guard let tag, !tag.isEmpty else { return random.uuidString }
    return "\(profileId.uuidString)|\(originHost)|\(tag)"
}

enum NotificationDecision: Equatable {
    case deliver
    /// The Slot's Notifications setting is off.
    case notificationsOff
    case duplicate
}

/// Whether a page notification is posted (SPEC 8.2). Slots with Notifications off drop theirs. Cross-Slot origin rule: a notification whose frame origin is another currently loaded
/// same-Profile Slot's Home host (and not the delivering Slot's own) is that Slot's copy.
/// A loaded Slot with Notifications off still counts in `loadedSlots`.
func notificationDecision(slot: Slot, originHost: String, loadedSlots: [Slot]) -> NotificationDecision {
    if !slot.notifications { return .notificationsOff }
    let isCopy = originHost != slot.homeHost && loadedSlots.contains { other in
        other.id != slot.id && other.profileId == slot.profileId && other.homeHost == originHost
    }
    return isCopy ? .duplicate : .deliver
}

/// `willPresent` options (SPEC 8.2): nothing while the Panel is on screen showing the originating Slot.
func foregroundPresentation(originSlot: UUID, panelShowing: UUID?, silent: Bool) -> UNNotificationPresentationOptions {
    if panelShowing == originSlot { return [] }
    return silent ? [.banner, .list] : [.banner, .list, .sound]
}
