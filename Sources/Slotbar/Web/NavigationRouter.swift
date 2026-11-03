import Foundation

/// What a Slot does with a main-frame navigation (SPEC 7.1).
enum Route: Equatable {
    /// Load in place.
    case stay
    /// Show this Slot and load the URL there (SPEC 6.2). May be the source Slot itself.
    case slot(UUID, URL)
    /// Cancel and hand the URL to macOS (`NSWorkspace.shared.open`): default browser or scheme handler.
    case browser(URL)
    /// Load in place and enter Sign-in mode (SPEC 7.2).
    case signIn
}

/// One navigation's first request, as seen by `decidePolicyFor navigationAction`.
struct NavigationRequest {
    var url: URL
    var isMainFrame: Bool
    /// Server redirect, or the Slot's own load of its starting, reopen or routed URL: never routed.
    var isExempt: Bool
    /// Cmd-click or middle-click.
    var opensOutside: Bool
}

enum NavigationRouter {
    static let pageLocalSchemes: Set<String> = ["about", "blob", "data", "javascript"]

    static func route(_ request: NavigationRequest, from source: Slot, slots: [Slot], inSignInMode: Bool) -> Route {
        guard request.isMainFrame else { return .stay }
        if request.isExempt { return isSignInHost(request.url) ? .signIn : .stay }
        if inSignInMode { return .stay }
        let scheme = request.url.scheme?.lowercased() ?? ""
        if pageLocalSchemes.contains(scheme) { return .stay }
        if scheme != "http" && scheme != "https" { return .browser(request.url) }

        var target = request.url
        if isGoogleWrapper(request.url) {
            guard let unwrapped = wrappedTarget(request.url) else { return .browser(request.url) }
            target = unwrapped
        }
        if request.opensOutside { return .browser(target) }
        if isSignInHost(target) { return .signIn }

        let host = target.host()?.lowercased()
        if host == homeHost(source) { return target == request.url ? .stay : .slot(source.id, target) }
        if let slot = slots.first(where: { $0.profileId == source.profileId && homeHost($0) == host }) {
            return .slot(slot.id, target)
        }
        return .browser(target)
    }

    static func homeHost(_ slot: Slot) -> String? {
        slot.url.host()?.lowercased()
    }

    /// `accounts.google.<TLD>` or `accounts.youtube.com`.
    static func isSignInHost(_ url: URL) -> Bool {
        guard let host = url.host()?.lowercased() else { return false }
        return host == "accounts.youtube.com" || isGoogleDomain(host, label: "accounts.google")
    }

    /// `google.<TLD>/url` or `www.google.<TLD>/url`.
    private static func isGoogleWrapper(_ url: URL) -> Bool {
        guard url.path() == "/url", var host = url.host()?.lowercased() else { return false }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return isGoogleDomain(host, label: "google")
    }

    /// The `q` or `url` parameter when it is an absolute `http`/`https` URL.
    private static func wrappedTarget(_ url: URL) -> URL? {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = items.first(where: { $0.name == "q" })?.value ?? items.first(where: { $0.name == "url" })?.value
        guard let value, let target = URL(string: value), target.host() != nil,
              let scheme = target.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return target
    }

    /// `<label>.<TLD>` where the TLD is one label (`com`, `it`) or `co.`/`com.` plus one label (`co.uk`, `com.au`).
    static func isGoogleDomain(_ host: String, label: String) -> Bool {
        guard host.hasPrefix(label + ".") else { return false }
        let tld = host.dropFirst(label.count + 1).split(separator: ".", omittingEmptySubsequences: false)
        switch tld.count {
        case 1: return !tld[0].isEmpty
        case 2: return (tld[0] == "co" || tld[0] == "com") && !tld[1].isEmpty
        default: return false
        }
    }
}
