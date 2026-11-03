import Foundation

/// The icon to fetch: the link `favicon.js` reported, else `/favicon.ico` on the Home host (SPEC 4.4).
func faviconURL(reported: URL?, slotURL: URL) -> URL? {
    if let reported { return reported }
    guard let scheme = slotURL.scheme, let host = slotURL.host() else { return nil }
    var components = URLComponents()
    components.scheme = scheme
    components.host = host
    components.port = slotURL.port
    components.path = "/favicon.ico"
    return components.url
}

/// Fetch when nothing is cached or the icon link changed; Chat Slots keep their first cached icon (SPEC 4.4).
func shouldFetchFavicon(slotURL: URL, lastIconURL: URL?, iconURL: URL, hasCachedIcon: Bool) -> Bool {
    guard hasCachedIcon else { return true }
    return slotURL.host() != "chat.google.com" && iconURL != lastIconURL
}

/// Slots whose cached icon must go: deleted, or URL or Profile changed (SPEC 4.4).
func faviconCachesToDelete(old: [Slot], new: [Slot]) -> Set<UUID> {
    let current = Dictionary(new.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    return Set(old.filter { slot in
        guard let now = current[slot.id] else { return true }
        return now.url != slot.url || now.profileId != slot.profileId
    }.map(\.id))
}
