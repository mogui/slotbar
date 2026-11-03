import WebKit

/// Builds every Slot webview: Profile data store, user agent, inspector flag (SPEC 1, 3.4).
@MainActor
enum WebViewFactory {
    /// Read once, at first use during launch.
    static let userAgent = UserAgent.fromDefaults()

    static func makeWebView(store: WKWebsiteDataStore) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = userAgent
        #if DEBUG
        webView.isInspectable = true
        #else
        webView.isInspectable = false
        #endif
        return webView
    }
}
