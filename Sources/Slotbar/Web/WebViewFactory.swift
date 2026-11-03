import WebKit

private let log = Log.logger("Web")

/// Builds every Slot webview: Profile data store, user agent, user scripts, notification shim, inspector flag, UI delegate (SPEC 1, 3.4, 7.6, 8.1).
/// The navigation delegate is the owning `SlotController`.
@MainActor
enum WebViewFactory {
    /// Read once, at first use during launch.
    static let userAgent = UserAgent.fromDefaults()

    /// Message handler name `favicon.js` posts the icon link to.
    static let faviconMessage = "slotbarFavicon"

    /// Loaded from the app bundle; nil under `swift run`, which then shows globe icons only.
    static let faviconScript: WKUserScript? = {
        guard let url = Bundle.main.url(forResource: "favicon", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            log.error("favicon.js not found in the app bundle")
            return nil
        }
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }()

    static func makeWebView(store: WKWebsiteDataStore, notifications: NotificationBridge, faviconHandler: WKScriptMessageHandler) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        notifications.install(in: configuration.userContentController)
        if let faviconScript {
            configuration.userContentController.addUserScript(faviconScript)
            configuration.userContentController.add(faviconHandler, name: faviconMessage)
        }
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = userAgent
        webView.uiDelegate = UIDelegate.shared
        #if DEBUG
        webView.isInspectable = true
        #else
        webView.isInspectable = false
        #endif
        return webView
    }
}
