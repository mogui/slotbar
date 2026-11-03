import WebKit

private let log = Log.logger("Slots")

/// Removes a Profile's on-disk data store.
@MainActor
protocol DataStoreRemover {
    func remove(_ id: UUID) async throws
}

struct WebKitDataStoreRemover: DataStoreRemover {
    func remove(_ id: UUID) async throws {
        try await WKWebsiteDataStore.remove(forIdentifier: id)
    }
}

/// One persistent `WKWebsiteDataStore` per Profile, shared by all its webviews, and the deletion queue (SPEC 3.4).
@MainActor
final class ProfileStores {
    private static let pendingKey = "PendingStoreDeletions"
    private var stores: [UUID: WKWebsiteDataStore] = [:]
    private let remover: DataStoreRemover
    private let defaults: UserDefaults

    init(remover: DataStoreRemover = WebKitDataStoreRemover(), defaults: UserDefaults = .standard) {
        self.remover = remover
        self.defaults = defaults
    }

    func store(for profileId: UUID) -> WKWebsiteDataStore {
        if let store = stores[profileId] { return store }
        let store = WKWebsiteDataStore(forIdentifier: profileId)
        stores[profileId] = store
        return store
    }

    /// Profile UUIDs whose store removal failed, retried at the next launch.
    var pendingDeletions: [UUID] {
        get { (defaults.stringArray(forKey: Self.pendingKey) ?? []).compactMap(UUID.init(uuidString:)) }
        set { defaults.set(newValue.map(\.uuidString), forKey: Self.pendingKey) }
    }

    /// Call after the Profile's webviews and notifications are gone; a failure queues the id.
    func delete(_ profileId: UUID) async {
        stores[profileId] = nil
        if await remove(profileId) { return }
        if !pendingDeletions.contains(profileId) { pendingDeletions.append(profileId) }
    }

    /// Call at launch before any webview is created.
    func retryPendingDeletions() async {
        for id in pendingDeletions where await remove(id) {
            pendingDeletions.removeAll { $0 == id }
        }
    }

    private func remove(_ id: UUID) async -> Bool {
        do {
            try await remover.remove(id)
            log.info("Removed data store \(id.uuidString, privacy: .public)")
            return true
        } catch {
            log.error("Data store \(id.uuidString, privacy: .public) removal failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
