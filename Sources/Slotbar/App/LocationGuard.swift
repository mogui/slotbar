import Foundation

/// Launch check for the "Move Slotbar to Applications" alert (SPEC 12.5).
enum LocationGuard {
    /// True when translocated or not under `/Applications` or `~/Applications` (compared by path components).
    static func needsMove(bundlePath: String, homeDirectory: String) -> Bool {
        let bundle = components(bundlePath)
        if bundle.contains("AppTranslocation") { return true }
        let allowed = [components("/Applications"), components(homeDirectory) + ["Applications"]]
        return !allowed.contains { bundle.count > $0.count && Array(bundle.prefix($0.count)) == $0 }
    }

    private static func components(_ path: String) -> [String] {
        URL(fileURLWithPath: path).standardizedFileURL.pathComponents
    }
}
