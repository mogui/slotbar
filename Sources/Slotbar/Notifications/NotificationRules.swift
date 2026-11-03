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

/// Conversation to open when a clicked notification has no page handler (SPEC 8.3). Google Chat posts through
/// `registration.showNotification` and opens the conversation from its service worker, out of the shim's reach.
/// Its `data` is a JSON string of `[messagePath, [[_, _, _, [_, topicId, group]]], messageId]`, where `group` holds the space
/// (`[["AAQA..."]]`) or DM (`[null, null, ["_SeR..."]]`) id, opened as `https://chat.google.com/app/chat/<id>`.
func notificationDeepLink(originHost: String, dataJSON: String?) -> URL? {
    guard originHost == "chat.google.com", let dataJSON, let data = jsonArray(dataJSON),
          data.count > 1, let messages = data[1] as? [Any], let message = messages.first as? [Any],
          message.count > 3, let target = message[3] as? [Any], target.count > 2,
          let id = firstString(in: target[2]), id.wholeMatch(of: /[A-Za-z0-9_-]+/) != nil else { return nil }
    return URL(string: "https://chat.google.com/app/chat/\(id)")
}

/// The array in `json`, also when `json` is a JSON string holding the array's JSON.
private func jsonArray(_ json: String) -> [Any]? {
    guard let bytes = json.data(using: .utf8),
          let value = try? JSONSerialization.jsonObject(with: bytes, options: .fragmentsAllowed) else { return nil }
    if let string = value as? String { return jsonArray(string) }
    return value as? [Any]
}

private func firstString(in value: Any) -> String? {
    if let string = value as? String { return string }
    if let array = value as? [Any] { return array.lazy.compactMap(firstString(in:)).first }
    return nil
}
