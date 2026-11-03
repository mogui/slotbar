import WebKit

/// Builds every Slot webview: Profile data store, user agent, notification shim, inspector flag, download and UI delegates (SPEC 1, 3.4, 7.4, 7.6, 8.1).
@MainActor
enum WebViewFactory {
    /// Read once, at first use during launch.
    static let userAgent = UserAgent.fromDefaults()

    static func makeWebView(store: WKWebsiteDataStore, notifications: NotificationBridge) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        notifications.install(in: configuration.userContentController)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = userAgent
        webView.navigationDelegate = DownloadManager.shared
        webView.uiDelegate = UIDelegate.shared
        #if DEBUG
        webView.isInspectable = true
        #else
        webView.isInspectable = false
        #endif
        return webView
    }
}
