import AppKit
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
        let webView = SlotWebView(frame: .zero, configuration: configuration)
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

/// Slot and Child window webview: the link context menu offers "Open Link in Slotbar" and "Open Link in Browser" (SPEC 7.1).
/// Each item runs WebKit's own "Open Link" with a one-shot `LinkOverride` the navigation delegate consumes.
final class SlotWebView: WKWebView {
    private var linkOverride: LinkOverride?

    func takeLinkOverride() -> LinkOverride? {
        defer { linkOverride = nil }
        return linkOverride
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        guard let index = menu.items.firstIndex(where: { $0.identifier?.rawValue == "WKMenuItemIdentifierOpenLink" }) else { return }
        let openLink = menu.items[index]
        openLink.isHidden = true
        menu.items.first { $0.identifier?.rawValue == "WKMenuItemIdentifierOpenLinkInNewWindow" }?.isHidden = true
        for (title, selector) in [("Open Link in Browser", #selector(openLinkOutside(_:))),
                                  ("Open Link in Slotbar", #selector(openLinkInside(_:)))] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            item.representedObject = openLink
            menu.insertItem(item, at: index)
        }
    }

    @objc private func openLinkInside(_ sender: NSMenuItem) { openLink(sender, override: .inside) }
    @objc private func openLinkOutside(_ sender: NSMenuItem) { openLink(sender, override: .outside) }

    private func openLink(_ sender: NSMenuItem, override: LinkOverride) {
        guard let openLink = sender.representedObject as? NSMenuItem, let action = openLink.action else { return }
        linkOverride = override
        NSApp.sendAction(action, to: openLink.target, from: openLink)
    }
}
