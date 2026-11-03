import AppKit
import WebKit

/// One Slot's open Child windows (SPEC 4.7), oldest first.
@MainActor
final class ChildWindows {
    private(set) var windows: [ChildWindowController] = []
    /// Shown in Child window titles.
    var profileName = "" {
        didSet { windows.forEach { $0.profileName = profileName } }
    }
    /// Frame for a new Child window from the `window.open` width and height (Panel's screen, off the Panel).
    var placement: (_ width: CGFloat?, _ height: CGFloat?) -> NSRect? = { _, _ in nil }
    /// A window closed (Cmd+W, `window.close()`, its crash, or `closeAll`).
    var onClose: (() -> Void)?
    /// A window's main frame committed a navigation to this URL.
    var onCommit: ((URL) -> Void)?

    var count: Int { windows.count }

    /// Opens a Child window on the configuration WebKit passed to `createWebViewWith`; returns its webview.
    func open(configuration: WKWebViewConfiguration, features: WKWindowFeatures) -> WKWebView {
        let width = features.width.map { CGFloat($0.doubleValue) }
        let height = features.height.map { CGFloat($0.doubleValue) }
        let frame = placement(width, height) ?? NSRect(origin: .zero, size: defaultChildWindowSize)
        let child = ChildWindowController(configuration: configuration, frame: frame, profileName: profileName)
        child.onClose = { [weak self] child in
            guard let self else { return }
            self.windows.removeAll { $0 === child }
            self.onClose?()
        }
        child.onCommit = { [weak self] url in self?.onCommit?(url) }
        windows.append(child)
        child.show()
        return child.webView
    }

    func contains(_ webView: WKWebView) -> Bool {
        windows.contains { $0.webView === webView }
    }

    /// `window.close()` from a Child window's page.
    func close(_ webView: WKWebView) {
        windows.first { $0.webView === webView }?.close()
    }

    func closeAll() {
        windows.forEach { $0.close() }
    }
}
