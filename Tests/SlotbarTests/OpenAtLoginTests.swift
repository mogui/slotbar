import Foundation
import Testing
@testable import Slotbar

/// Stands in for `SMAppService.mainApp` (system boundary).
@MainActor
final class FakeLoginItem: LoginItemService {
    struct Failure: LocalizedError {
        var errorDescription: String? { "Operation not permitted" }
    }

    var isEnabled = false
    var registerFails = false
    var unregisterFails = false
    var registerCalls = 0
    /// False models `.requiresApproval`: `register()` returns but the item is not enabled yet.
    var registerEnables = true

    func register() throws {
        registerCalls += 1
        if registerFails { throw Failure() }
        isEnabled = registerEnables
    }

    func unregister() throws {
        if unregisterFails { throw Failure() }
        isEnabled = false
    }
}

@MainActor
@Suite struct OpenAtLoginTests {
    let store = SettingsStore(directory: FileManager.default.temporaryDirectory
        .appendingPathComponent("OpenAtLoginTests-\(UUID().uuidString)"))
    let service = FakeLoginItem()

    @Test func turningOnRegistersAndSaves() {
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        #expect(service.isEnabled)
        #expect(store.settings.general.openAtLogin)
    }

    @Test func turningOffUnregistersAndSaves() {
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        openAtLogin.set(false)
        #expect(!service.isEnabled)
        #expect(!store.settings.general.openAtLogin)
    }

    @Test func registerFailureKeepsBoxOffWithError() {
        service.registerFails = true
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        #expect(!store.settings.general.openAtLogin)
        #expect(openAtLogin.error == "Operation not permitted")
    }

    @Test func unregisterFailureStillSavesOffWithError() {
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        service.unregisterFails = true
        openAtLogin.set(false)
        #expect(!store.settings.general.openAtLogin)
        #expect(openAtLogin.error == "Operation not permitted")
    }

    @Test func laterSuccessClearsError() {
        service.registerFails = true
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        service.registerFails = false
        openAtLogin.set(true)
        #expect(openAtLogin.error == nil)
    }

    @Test func launchReregistersWhenOnButNotEnabled() {
        store.update { $0.general.openAtLogin = true }
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.healAtLaunch()
        #expect(service.registerCalls == 1)
        #expect(store.settings.general.openAtLogin)
    }

    @Test func launchLeavesEnabledItemAlone() {
        store.update { $0.general.openAtLogin = true }
        service.isEnabled = true
        OpenAtLogin(service: service, store: store).healAtLaunch()
        #expect(service.registerCalls == 0)
    }

    @Test func launchLeavesOffAlone() {
        OpenAtLogin(service: service, store: store).healAtLaunch()
        #expect(service.registerCalls == 0)
    }

    @Test func launchFailureTurnsOffWithError() {
        store.update { $0.general.openAtLogin = true }
        service.registerFails = true
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.healAtLaunch()
        #expect(!store.settings.general.openAtLogin)
        #expect(openAtLogin.error == "Operation not permitted")
    }

    @Test func registerNeedingApprovalCountsAsOn() {
        service.registerEnables = false
        let openAtLogin = OpenAtLogin(service: service, store: store)
        openAtLogin.set(true)
        #expect(store.settings.general.openAtLogin)
        #expect(openAtLogin.error == nil)
    }
}
