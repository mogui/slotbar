import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2).
@MainActor
final class SlotController {
    var slot: Slot
    private let stores: ProfileStores
    private let notifications: NotificationBridge
    private(set) var webView: WKWebView?

    init(slot: Slot, stores: ProfileStores, notifications: NotificationBridge) {
        self.slot = slot
        self.stores = stores
        self.notifications = notifications
    }

    /// Loads the Slot at its starting URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId), notifications: notifications)
        webView.load(URLRequest(url: slot.url))
        self.webView = webView
        log.debug("Loading Slot \(self.slot.id, privacy: .public)")
        return webView
    }
}
