import AppKit
import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2), and routes its navigations (SPEC 7).
@MainActor
final class SlotController: NSObject, WKNavigationDelegate {
    var slot: Slot
    /// All Slots in list order, for routing to a same-Profile Slot.
    var slots: [Slot] = []
    /// Show the Slot with this id and load the URL there.
    var onRoute: ((UUID, URL) -> Void)?
    private let stores: ProfileStores
    private(set) var webView: WKWebView?
    private var signInMode = SignInMode()
    /// The next main-frame request is the Slot's own load (starting, reopen or routed URL).
    private var nextLoadIsOwn = false
    /// A main-frame navigation has started and not committed or failed yet.
    private var mainFrameProvisional = false

    var isInSignInMode: Bool { signInMode.isActive(at: Date()) }

    init(slot: Slot, stores: ProfileStores) {
        self.slot = slot
        self.stores = stores
    }

    /// Loads the Slot at its starting URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        return load(at: slot.url)
    }

    /// Loads `url` (never routed): creates the webview when Unloaded, else navigates in place.
    @discardableResult
    func load(at url: URL) -> WKWebView {
        let webView = self.webView ?? {
            let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId))
            webView.navigationDelegate = self
            self.webView = webView
            log.debug("Loading Slot \(self.slot.id, privacy: .public)")
            return webView
        }()
        nextLoadIsOwn = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        // No target frame: a popup, handled by `createWebViewWith` (SPEC 7.3).
        guard let frame = action.targetFrame, let url = action.request.url else { return decisionHandler(.allow) }
        var isExempt = false
        if frame.isMainFrame {
            let isRedirect = mainFrameProvisional && action.navigationType == .other
            isExempt = nextLoadIsOwn || isRedirect || action.navigationType == .backForward || action.navigationType == .reload
            nextLoadIsOwn = false
        }
        let request = NavigationRequest(url: url, isMainFrame: frame.isMainFrame, isExempt: isExempt,
                                        opensOutside: action.modifierFlags.contains(.command) || action.buttonNumber == 1)
        let route = NavigationRouter.route(request, from: slot, slots: slots, inSignInMode: isInSignInMode)
        #if DEBUG
        if frame.isMainFrame {
            log.debug("Route \(url.absoluteString, privacy: .public) from Slot \(self.slot.id, privacy: .public) exempt=\(isExempt) signIn=\(self.isInSignInMode): \(String(describing: route), privacy: .public)")
        }
        #endif
        switch route {
        case .stay:
            decisionHandler(.allow)
        case .signIn:
            signInMode.enter(at: Date())
            decisionHandler(.allow)
        case .slot(let id, let target):
            decisionHandler(.cancel)
            if id == slot.id { load(at: target) } else { onRoute?(id, target) }
        case .browser(let target):
            decisionHandler(.cancel)
            NSWorkspace.shared.open(target)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        mainFrameProvisional = true
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        mainFrameProvisional = false
        if let url = webView.url { signInMode.didCommit(url, homeHost: NavigationRouter.homeHost(slot)) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        mainFrameProvisional = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        mainFrameProvisional = false
    }
}
