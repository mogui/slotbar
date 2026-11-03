import os

/// Logging convention: one `Logger` per module, category = module folder name
/// (`App`, `Model`, `Panel`, `Slots`, `Web`, `Notifications`, `Unread`, `Settings`).
/// Usage: `private let log = Log.logger("Panel")`.
enum Log {
    static let subsystem = "io.github.mogui.slotbar"

    static func logger(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
