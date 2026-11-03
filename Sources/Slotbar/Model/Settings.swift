import Foundation

struct Settings: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var general: General
    var profiles: [Profile]
    var slots: [Slot]
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
