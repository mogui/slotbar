import AppKit
import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2).
@MainActor
final class SlotController {
    var slot: Slot
    private let stores: ProfileStores
    private(set) var webView: WKWebView?

    init(slot: Slot, stores: ProfileStores) {
        self.slot = slot
        self.stores = stores
    }

    /// Loads the Slot at its starting URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId))
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
}
