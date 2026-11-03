import WebKit

private let log = Log.logger("Slots")

/// Keeps one Slot's cached favicon up to date from the icon link its page reports (SPEC 3.1, 4.4).
@MainActor
final class FaviconFetcher {
    /// The Slot the icon belongs to; a fetch finishing after a URL or Profile change is dropped.
    var slot: Slot {
        didSet { if !slot.hasSameStart(as: oldValue) { lastIconURL = nil } }
    }
    /// A new favicon was cached.
    var onChange: ((_ slotId: UUID) -> Void)?
    private let stores: ProfileStores
    private let favicons: FaviconCache
    /// Icon link last fetched in this session.
    private var lastIconURL: URL?

    init(slot: Slot, stores: ProfileStores, favicons: FaviconCache) {
        self.slot = slot
        self.stores = stores
        self.favicons = favicons
    }

    func iconLinkReported(_ body: Any) {
        let reported = (body as? String).flatMap(URL.init(string:))
        guard let iconURL = faviconURL(reported: reported, slotURL: slot.url),
              shouldFetchFavicon(slotURL: slot.url, lastIconURL: lastIconURL, iconURL: iconURL,
                                 hasCachedIcon: favicons.hasIcon(for: slot.id)) else { return }
        lastIconURL = iconURL
        let slot = slot
        let store = stores.store(for: slot.profileId)
        Task { [weak self] in
            guard let data = await Self.fetch(iconURL, store: store) else { return }
            // Dropped if the Slot was deleted or moved to another URL or Profile meanwhile.
            guard let self, self.slot.hasSameStart(as: slot) else { return }
            self.favicons.store(imageData: data, for: slot.id)
            if self.favicons.hasIcon(for: slot.id) { self.onChange?(slot.id) }
        }
    }

    /// Fetches with the Profile's cookies and the Slotbar user agent, so the icon comes "through the Slot's data store".
    private static func fetch(_ url: URL, store: WKWebsiteDataStore) async -> Data? {
        let cookies = await store.httpCookieStore.allCookies()
        let configuration = URLSessionConfiguration.ephemeral
        cookies.forEach { configuration.httpCookieStorage?.setCookie($0) }
        configuration.httpAdditionalHeaders = ["User-Agent": WebViewFactory.userAgent]
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            log.debug("Favicon fetch failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
