import Foundation

struct Settings: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var general: General
    var profiles: [Profile]
    var slots: [Slot]

    /// Flips one Slot's `notifications` (Rail right-click check item, SPEC 4.4).
    mutating func toggleNotifications(slot id: UUID) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].notifications.toggle()
    }
}

struct General: Codable, Equatable, Sendable {
    enum PanelEdge: String, Codable, Sendable {
        case left, right, top, bottom
    }

    struct PanelDepth: Codable, Equatable, Sendable {
        var horizontal: Double
        var vertical: Double
    }

    var panelEdge: PanelEdge
    var hideOnFocusLoss: Bool
    var openAtLogin: Bool
    var panelDepth: PanelDepth
}

struct Profile: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var color: String
}

struct Slot: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var url: URL
    var profileId: UUID
    var label: String?
    var keepAlive: Bool
    var notifications: Bool

    private enum CodingKeys: String, CodingKey {
        case id, url, profileId, label, keepAlive, notifications
    }

    init(id: UUID, url: URL, profileId: UUID, label: String?, keepAlive: Bool, notifications: Bool) {
        self.id = id
        self.url = url
        self.profileId = profileId
        self.label = label
        self.keepAlive = keepAlive
        self.notifications = notifications
    }

    // `label` is a required key whose value may be null (SPEC 3.3); synthesized coding would omit it.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        url = try c.decode(URL.self, forKey: .url)
        profileId = try c.decode(UUID.self, forKey: .profileId)
        label = try c.decode(String?.self, forKey: .label)
        keepAlive = try c.decode(Bool.self, forKey: .keepAlive)
        notifications = try c.decode(Bool.self, forKey: .notifications)
    }

    /// The starting URL's host, lowercased (SPEC 7.1).
    var homeHost: String? { url.host()?.lowercased() }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(url, forKey: .url)
        try c.encode(profileId, forKey: .profileId)
        try c.encode(label, forKey: .label)
        try c.encode(keepAlive, forKey: .keepAlive)
        try c.encode(notifications, forKey: .notifications)
    }
}

extension Settings {
    /// First-run preset (SPEC 11).
    static func preset() -> Settings {
        let profile = Profile(id: UUID(), name: "Default", color: "#007AFF")
        func slot(_ url: String, keepAlive: Bool) -> Slot {
            Slot(id: UUID(), url: URL(string: url)!, profileId: profile.id,
                 label: nil, keepAlive: keepAlive, notifications: true)
        }
        return Settings(
            schemaVersion: 1,
            general: General(panelEdge: .right, hideOnFocusLoss: true, openAtLogin: false,
                             panelDepth: .init(horizontal: 0.45, vertical: 0.70)),
            profiles: [profile],
            slots: [
                slot("https://mail.google.com/", keepAlive: true),
                slot("https://calendar.google.com/", keepAlive: false),
                slot("https://chat.google.com/", keepAlive: true),
            ]
        )
    }
}

extension Settings {
    /// Sets a null label to `<page title> - <Profile name>`; set labels stay frozen, a blank title waits for the next load (SPEC 3.1).
    mutating func applyAutoLabel(slotId: UUID, pageTitle: String) {
        let title = pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let index = slots.firstIndex(where: { $0.id == slotId }), slots[index].label == nil,
              let profile = profiles.first(where: { $0.id == slots[index].profileId }) else { return }
        slots[index].label = "\(title) - \(profile.name)"
    }
}

extension Settings {
    /// Appends a Profile named "Profile N" (N = count + 1, bumped past taken names) in the next palette color (SPEC 10.2).
    mutating func addProfile(id: UUID) {
        var number = profiles.count + 1
        while profiles.contains(where: { $0.name == "Profile \(number)" }) { number += 1 }
        profiles.append(Profile(id: id, name: "Profile \(number)",
                                color: ProfilePalette.colorForNewProfile(existing: profiles)))
    }

    /// A blank name is not saved (schema `minLength: 1`, SPEC 3.3).
    mutating func renameProfile(_ id: UUID, to name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = name
    }

    func slots(inProfile id: UUID) -> [Slot] {
        slots.filter { $0.profileId == id }
    }

    /// Removes the Profile and its Slots; the last Profile may go too (SPEC 5, 10.2).
    mutating func deleteProfile(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        slots.removeAll { $0.profileId == id }
    }
}
