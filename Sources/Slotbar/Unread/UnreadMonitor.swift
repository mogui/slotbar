import WebKit

private let log = Log.logger("Unread")

/// Tracks one loaded Slot's Unread state through the adapter chosen by its Home host (SPEC 8.4).
@MainActor
final class UnreadMonitor: NSObject, WKScriptMessageHandler {
    static let handlerName = "slotbarUnread"

    private(set) var state: UnreadState = .none
    var onChange: (() -> Void)?
    private let homeHost: String
    private var gmail = GmailUnread()
    private var titleObservation: NSKeyValueObservation?
    /// Child windows share the Slot's user content controller; only this webview's page counts (SPEC 8.4).
    private weak var webView: WKWebView?

    init(homeHost: String) {
        self.homeHost = homeHost
    }

    /// Installs the adapter before the webview's first load.
    func attach(to webView: WKWebView) {
        self.webView = webView
        let script: String
        switch homeHost {
        case "mail.google.com": script = "unread-gmail"
        case "chat.google.com": script = "unread-chat"
        default:
            titleObservation = webView.observe(\.title, options: [.initial, .new]) { webView, _ in
                MainActor.assumeIsolated { [weak self] in
                    self?.update(titleUnread(webView.title ?? ""))
                }
            }
            return
        }
        guard let url = Bundle.main.url(forResource: script, withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            log.error("Missing \(script, privacy: .public).js; Unread state off for \(self.homeHost, privacy: .public)")
            return
        }
        let controller = webView.configuration.userContentController
        controller.add(self, name: Self.handlerName)
        controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.webView === webView, let body = message.body as? [String: Any] else { return }
        switch body["kind"] as? String {
        case "chat":
            update(chatUnread(faviconHref: body["href"] as? String, last: state))
        case "gmail":
            let count = (body["count"] as? NSNumber)?.intValue ?? 0
            let signal: GmailSignal
            switch body["source"] as? String {
            case "dom": signal = .dom(count)
            case "atom": signal = .atom(count)
            default: signal = .failed
            }
            if let source = gmail.apply(signal) {
                log.info("Gmail unread source switched to \(source.rawValue, privacy: .public)")
            }
            update(gmail.state)
        default:
            break
        }
    }

    private func update(_ new: UnreadState) {
        guard new != state else { return }
        state = new
        onChange?()
    }
}
