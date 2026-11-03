import Foundation

/// User agent set on every webview (SPEC 1).
enum UserAgent {
    /// Desktop Firefox on macOS; bump the version with releases.
    static let firefox = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:157.0) Gecko/20100101 Firefox/157.0"

    /// Empty or missing override uses `firefox`.
    static func resolve(override: String?) -> String {
        guard let override, !override.trimmingCharacters(in: .whitespaces).isEmpty else { return firefox }
        return override
    }

    /// Hidden `defaults write io.github.mogui.slotbar UserAgent "<string>"`, read at launch.
    static func fromDefaults(_ defaults: UserDefaults = .standard) -> String {
        resolve(override: defaults.string(forKey: "UserAgent"))
    }
}
