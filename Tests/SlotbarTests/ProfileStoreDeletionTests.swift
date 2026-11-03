import Foundation
import Testing
@testable import Slotbar

/// Stands in for `WKWebsiteDataStore.remove(forIdentifier:)` (system boundary).
@MainActor
final class FakeStoreRemover: DataStoreRemover {
    struct Failure: Error {}

    var failing: Set<UUID> = []
    var removed: [UUID] = []

    func remove(_ id: UUID) async throws {
        if failing.contains(id) { throw Failure() }
        removed.append(id)
    }
}

@MainActor
@Suite struct ProfileStoreDeletionTests {
    let defaults = UserDefaults(suiteName: "ProfileStoreDeletionTests-\(UUID().uuidString)")!
    let remover = FakeStoreRemover()

    @Test func successfulDeletionRemovesTheStore() async {
        let id = UUID()
        let stores = ProfileStores(remover: remover, defaults: defaults)
        await stores.delete(id)
        #expect(remover.removed == [id])
        #expect(stores.pendingDeletions.isEmpty)
    }

    @Test func failedDeletionIsKeptForTheNextLaunch() async {
        let id = UUID()
        remover.failing = [id]
        await ProfileStores(remover: remover, defaults: defaults).delete(id)
        #expect(ProfileStores(remover: remover, defaults: defaults).pendingDeletions == [id])
    }

    @Test func retryRemovesSucceededAndKeepsFailed() async {
        let fixed = UUID(), stuck = UUID()
        remover.failing = [fixed, stuck]
        let stores = ProfileStores(remover: remover, defaults: defaults)
        await stores.delete(fixed)
        await stores.delete(stuck)
        remover.failing = [stuck]
        await stores.retryPendingDeletions()
        #expect(remover.removed == [fixed])
        #expect(stores.pendingDeletions == [stuck])
    }

    @Test func pendingIsStoredAsUUIDStrings() async {
        let id = UUID()
        remover.failing = [id]
        await ProfileStores(remover: remover, defaults: defaults).delete(id)
        #expect(defaults.stringArray(forKey: "PendingStoreDeletions") == [id.uuidString])
    }
}
