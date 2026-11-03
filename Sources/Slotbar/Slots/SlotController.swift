import AppKit
import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2), and keeps its favicon and auto-label up to date (SPEC 3.1, 4.4).
@MainActor
final class SlotController: NSObject {
    var slot: Slot
    private let stores: ProfileStores
    private let favicons: FaviconCache
    private(set) var webView: WKWebView?
    /// Icon link last fetched in this session.
    private var lastIconURL: URL?

    /// Page title of a completed main-frame load while the Slot's label is null.
    var onUnlabeledLoad: ((_ slotId: UUID, _ pageTitle: String) -> Void)?
    /// A new favicon was cached.
    var onFaviconChange: ((_ slotId: UUID) -> Void)?

    init(slot: Slot, stores: ProfileStores, favicons: FaviconCache) {
        self.slot = slot
        self.stores = stores
        self.favicons = favicons
    }

    /// Loads the Slot at its starting URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId),
                                                 faviconHandler: WeakScriptHandler(self))
        webView.navigationDelegate = self
        webView.load(URLRequest(url: slot.url))
        self.webView = webView
        log.debug("Loading Slot \(self.slot.id, privacy: .public)")
        return webView
    }

    /// Go home, open current page in browser, reload (SPEC 7.5). Loads the Slot first if needed.
    func perform(_ action: SlotAction) {
        switch action {
        case .goHome:
            load().load(URLRequest(url: slot.url))
        case .openInBrowser:
            NSWorkspace.shared.open(webView?.url ?? slot.url)
        case .reload:
            if let webView { webView.reload() } else { load() }
        case .toggleNotifications:
            break
        }
    }

    fileprivate func iconLinkReported(_ body: Any) {
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
            guard let self, self.slot.url == slot.url, self.slot.profileId == slot.profileId else { return }
            self.favicons.store(imageData: data, for: slot.id)
            if self.favicons.hasIcon(for: slot.id) { self.onFaviconChange?(slot.id) }
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

extension SlotController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard slot.label == nil else { return }
        onUnlabeledLoad?(slot.id, webView.title ?? "")
    }
}

/// `WKUserContentController` retains its handlers; this breaks the SlotController -> webview -> handler cycle.
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var controller: SlotController?

    init(_ controller: SlotController) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated {
            guard message.frameInfo.isMainFrame else { return }
            controller?.iconLinkReported(message.body)
        }
    }
}
