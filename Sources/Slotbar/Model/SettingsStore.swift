import Foundation
import Observation

private let log = Log.logger("Model")

/// Owns `settings.json` (SPEC 3.2): loads it at init, writes every change atomically,
/// and publishes changes to SwiftUI (via Observation) and to controllers (via `observe`).
@MainActor
@Observable
final class SettingsStore {
    private(set) var settings: Settings

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private var observers: [(Settings) -> Void] = []

    /// Calls `handler` with the new settings after every `update`.
    func observe(_ handler: @escaping (Settings) -> Void) {
        observers.append(handler)
    }

    /// Applies `change`, writes the file and notifies observers.
    func update(_ change: (inout Settings) -> Void) {
        change(&settings)
        write()
        for observer in observers {
            observer(settings)
        }
    }

    init(directory: URL, now: () -> Date = Date.init) {
        fileURL = directory.appendingPathComponent("settings.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let data = try? Data(contentsOf: fileURL) else {
            log.info("No settings file; writing the first-run preset")
            settings = .preset()
            write()
            return
        }
        do {
            var loaded = try JSONDecoder().decode(Settings.self, from: data)
            guard loaded.schemaVersion == 1 else {
                throw SchemaVersionError(version: loaded.schemaVersion)
            }
            let profileIds = Set(loaded.profiles.map(\.id))
            let slotCount = loaded.slots.count
            loaded.slots.removeAll { !profileIds.contains($0.profileId) }
            settings = loaded
            if loaded.slots.count != slotCount {
                log.info("Dropped \(slotCount - loaded.slots.count) Slots of missing Profiles")
                write()
            }
        } catch {
            log.error("Unreadable settings file: \(String(describing: error), privacy: .public)")
            Self.setAside(fileURL, at: now())
            settings = .preset()
            write()
        }
    }

    private struct SchemaVersionError: Error {
        let version: Int
    }

    /// Renames an unreadable file to `settings.corrupt-<yyyyMMdd-HHmmss>.json` (local time).
    private static func setAside(_ file: URL, at date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let target = file.deletingLastPathComponent()
            .appendingPathComponent("settings.corrupt-\(formatter.string(from: date)).json")
        do {
            try FileManager.default.moveItem(at: file, to: target)
        } catch {
            log.error("Setting aside settings file failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func write() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            try encoder.encode(settings).write(to: fileURL, options: .atomic)
        } catch {
            log.error("Writing settings failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
