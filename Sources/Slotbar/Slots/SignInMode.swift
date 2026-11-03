import Foundation

/// A Slot's Sign-in mode (SPEC 7.2).
struct SignInMode {
    static let timeout: TimeInterval = 10 * 60
    private var enteredAt: Date?

    /// Entering while already active keeps the first entry time.
    mutating func enter(at now: Date) {
        if !isActive(at: now) { enteredAt = now }
    }

    /// A main-frame commit on the Home host ends the mode.
    mutating func didCommit(_ url: URL, homeHost: String?) {
        if url.host()?.lowercased() == homeHost { enteredAt = nil }
    }

    func isActive(at now: Date) -> Bool {
        guard let enteredAt else { return false }
        return now.timeIntervalSince(enteredAt) < Self.timeout
    }
}
