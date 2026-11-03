import AppKit
import WebKit

private let log = Log.logger("Web")

/// One popup that stays in the app (SPEC 4.7): a floating window on all Spaces holding a webview built from
/// the configuration WebKit passed to `createWebViewWith` (the Slot's data store and a real `window.opener`).
/// Its navigations are not routed; non-web schemes go to their macOS handler.
@MainActor
final class ChildWindowController: NSObject, NSWindowDelegate, WKNavigationDelegate {
    let webView: WKWebView
    let window: ChildWindow
    /// Called once, after the window closed for any reason.
    var onClose: ((ChildWindowController) -> Void)?
    var profileName: String {
        didSet { updateTitle() }
    }
    private var titleObservation: NSKeyValueObservation?
    /// Ordered out by a Panel hide, to be ordered back in on show.
    private var hiddenWithPanel = false

    init(configuration: WKWebViewConfiguration, frame: NSRect, profileName: String) {
        self.profileName = profileName
        webView = WKWebView(frame: .zero, configuration: configuration)
        window = ChildWindow(contentRect: frame, styleMask: [.titled, .resizable, .closable, .miniaturizable],
                             backing: .buffered, defer: false)
        super.init()
        webView.customUserAgent = WebViewFactory.userAgent
        webView.uiDelegate = UIDelegate.shared
        webView.navigationDelegate = self
        #if DEBUG
        webView.isInspectable = true
        #else
        webView.isInspectable = false
        #endif
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = webView
        window.setFrame(frame, display: false)
        window.delegate = self
        titleObservation = webView.observe(\.title, options: [.initial]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.updateTitle() }
        }
    }

    func show() {
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window.close()
    }

    /// Panel hide: order out, never close. A minimized window stays minimized (SPEC 4.7).
    func hideWithPanel() {
        guard window.isVisible, !window.isMiniaturized else { return }
        hiddenWithPanel = true
        window.orderOut(nil)
    }

    /// Panel show: back in place, without taking key from the Panel.
    func showWithPanel() {
        guard hiddenWithPanel else { return }
        hiddenWithPanel = false
        window.orderFront(nil)
    }

    private func updateTitle() {
        window.title = childWindowTitle(pageTitle: webView.title, profileName: profileName)
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        titleObservation = nil
        webView.stopLoading()
        onClose?(self)
        onClose = nil
    }

    // MARK: WKNavigationDelegate - downloads via DownloadManager (SPEC 7.4), crash closes only this window

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        if action.shouldPerformDownload { return decisionHandler(.download) }
        let scheme = action.request.url?.scheme?.lowercased() ?? ""
        if action.targetFrame?.isMainFrame == true, let url = action.request.url,
           !["http", "https"].contains(scheme), !NavigationRouter.pageLocalSchemes.contains(scheme) {
            decisionHandler(.cancel)
            NSWorkspace.shared.open(url)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
        DownloadManager.shared.webView(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        log.info("Child window page crashed; closing it")
        close()
    }
}

/// `Cmd+W` closes the Child window (SPEC 9); the Panel shortcuts do not apply here.
final class ChildWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        if modifiers == .command, event.charactersIgnoringModifiers?.lowercased() == "w" {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
