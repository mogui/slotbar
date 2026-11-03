import WebKit

/// One persistent `WKWebsiteDataStore` per Profile, shared by all its webviews (SPEC 3.4).
@MainActor
final class ProfileStores {
    private var stores: [UUID: WKWebsiteDataStore] = [:]

    func store(for profileId: UUID) -> WKWebsiteDataStore {
        if let store = stores[profileId] { return store }
        let store = WKWebsiteDataStore(forIdentifier: profileId)
        stores[profileId] = store
        return store
    }
}
