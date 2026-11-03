import Foundation
import Observation
import ServiceManagement

private let log = Log.logger("App")

/// The login item, `SMAppService.mainApp` in the app.
@MainActor
protocol LoginItemService: AnyObject {
    var isEnabled: Bool { get }
    func register() throws
    func unregister() throws
}

/// Open at login (SPEC 10.1, 12.5): keeps `general.openAtLogin` and the login item in step.
@MainActor
@Observable
final class OpenAtLogin {
    /// Inline error shown under the checkbox in Settings > General.
    private(set) var error: String?

    @ObservationIgnored private let service: LoginItemService
    @ObservationIgnored private let store: SettingsStore

    init(service: LoginItemService, store: SettingsStore) {
        self.service = service
        self.store = store
    }

    /// The user's choice wins when turning off: the box is saved off even if unregistering fails.
    func set(_ on: Bool) {
        do {
            if on { try service.register() } else { try service.unregister() }
            store.update { $0.general.openAtLogin = on }
            self.error = nil
        } catch {
            log.error("Open at login change failed: \(error.localizedDescription, privacy: .public)")
            if !on { store.update { $0.general.openAtLogin = false } }
            self.error = error.localizedDescription
        }
    }

    /// Launch self-heal (SPEC 12.5): re-registers a saved "on" the system no longer has enabled.
    func healAtLaunch() {
        guard store.settings.general.openAtLogin, !service.isEnabled else { return }
        set(true)
        if error != nil { store.update { $0.general.openAtLogin = false } }
    }
}

/// `SMAppService.mainApp`; `register()` returning counts as success even while it awaits approval.
@MainActor
final class MainAppLoginItem: LoginItemService {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}
