import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2).
@MainActor
final class SlotController {
    var slot: Slot
    private let stores: ProfileStores
    private(set) var webView: WKWebView?
    /// Called when the loaded Slot's Unread state changes.
    var onUnreadChange: (() -> Void)?
    private var unreadMonitor: UnreadMonitor?

    init(slot: Slot, stores: ProfileStores) {
        self.slot = slot
        self.stores = stores
    }

    /// Loads the Slot at its starting URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId))
        let monitor = UnreadMonitor(homeHost: slot.url.host() ?? "")
        monitor.onChange = { [weak self] in self?.onUnreadChange?() }
        monitor.attach(to: webView)
        unreadMonitor = monitor
        webView.load(URLRequest(url: slot.url))
        self.webView = webView
        log.debug("Loading Slot \(self.slot.id, privacy: .public)")
        return webView
    }

    /// The Slot's Unread state while loaded; nil when Unloaded (contributes nothing).
    var unread: UnreadState? {
        webView == nil ? nil : unreadMonitor?.state
    }
}
