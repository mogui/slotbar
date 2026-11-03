import UserNotifications
import WebKit

private let log = Log.logger("Notifications")

/// Posts page notifications from the `slotbarNotify` shim through Notification Center and routes clicks back (SPEC 8.1-8.3).
@MainActor
final class NotificationBridge: NSObject {
    static let handlerName = "slotbarNotify"

    /// Owning Slot of a webview (a Child window maps to its owning Slot).
    var slotForWebView: (WKWebView) -> Slot? = { _ in nil }
    /// Slots that currently have a page.
    var loadedSlots: () -> [Slot] = { [] }
    /// The Slot the Panel shows while on screen, else nil.
    var panelShowingSlot: () -> UUID? = { nil }
    /// Shows the Panel on a Slot through the normal show path.
    var showSlot: (UUID) -> Void = { _ in }
    /// Loads a URL in a Slot and shows it (the routed-link path).
    var openURL: (UUID, URL) -> Void = { _, _ in }

    /// Where a native id was raised, to call its `onclick`.
    private struct Origin {
        weak var webView: WKWebView?
        let frame: WKFrameInfo
        let requestId: String
        /// Opened on click when no page handler takes it (SPEC 8.3).
        let deepLink: URL?
    }

    private var origins: [String: Origin] = [:]
    /// Latest native id per request id, so closing a replaced notification leaves its replacement.
    private var latestNativeId: [String: String] = [:]
    private let center: UNUserNotificationCenter?

    override init() {
        // UNUserNotificationCenter needs an app bundle; `swift run` has none.
        center = Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()
        super.init()
        if center == nil { log.error("No app bundle: notifications are disabled") }
        center?.delegate = self
    }

    /// Asks for authorization while it has never been asked, i.e. at first launch (SPEC 8.2).
    func requestAuthorizationIfNeeded() {
        guard let center else { return }
        Task {
            guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                log.info("Notification authorization granted: \(granted)")
            } catch {
                log.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// The shim script, from `Contents/Resources`; nil outside the app bundle.
    static let shim: WKUserScript? = {
        guard let url = Bundle.main.url(forResource: "notification-shim", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            log.error("notification-shim.js not found")
            return nil
        }
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
    }()

    /// Installs the shim and the reply handler on a new webview configuration.
    func install(in controller: WKUserContentController) {
        guard let shim = Self.shim else { return }
        controller.addUserScript(shim)
        controller.addScriptMessageHandler(self, contentWorld: .page, name: Self.handlerName)
    }

    /// Removes the delivered notifications of deleted Slots (SPEC 8.2).
    func removeDelivered(slotIds: Set<UUID>) {
        guard let center, !slotIds.isEmpty else { return }
        let threads = Set(slotIds.map(\.uuidString))
        Task {
            let ids = await center.deliveredNotifications()
                .filter { threads.contains($0.request.content.threadIdentifier) }
                .map(\.request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    private func show(_ body: [String: Any], message: WKScriptMessage) -> String {
        let nativeId = UUID().uuidString
        guard let center, let webView = message.webView, let slot = slotForWebView(webView) else { return nativeId }
        let originHost = message.frameInfo.securityOrigin.host
        let tag = body["tag"] as? String
        let silent = body["silent"] as? Bool ?? false
        let pageId = body["pageId"] as? String ?? ""

        switch notificationDecision(slot: slot, originHost: originHost, loadedSlots: loadedSlots()) {
        case .notificationsOff:
            log.debug("Dropped notification: Notifications off in Slot \(slot.id, privacy: .public)")
            return nativeId
        case .duplicate:
            log.debug("Dropped \(originHost, privacy: .public) copy in Slot \(slot.id, privacy: .public)")
            return nativeId
        case .deliver:
            break
        }

        let requestId = notificationRequestId(profileId: slot.profileId, originHost: originHost, tag: tag)
        let content = UNMutableNotificationContent()
        content.title = body["title"] as? String ?? ""
        content.subtitle = slot.label ?? slot.url.host() ?? ""
        content.body = body["body"] as? String ?? ""
        content.threadIdentifier = slot.id.uuidString
        content.userInfo = ["slotId": slot.id.uuidString, "pageId": pageId, "nativeId": nativeId]
        content.sound = silent ? nil : .default
        content.interruptionLevel = .active

        let deepLink = notificationDeepLink(originHost: originHost, dataJSON: body["data"] as? String)
        origins[nativeId] = Origin(webView: webView, frame: message.frameInfo, requestId: requestId, deepLink: deepLink)
        latestNativeId[requestId] = nativeId
        center.add(UNNotificationRequest(identifier: requestId, content: content, trigger: nil)) { error in
            if let error { log.error("Posting notification failed: \(error.localizedDescription, privacy: .public)") }
        }
        return nativeId
    }

    private func close(nativeId: String) {
        guard let origin = origins.removeValue(forKey: nativeId),
              latestNativeId[origin.requestId] == nativeId else { return }
        latestNativeId[origin.requestId] = nil
        center?.removeDeliveredNotifications(withIdentifiers: [origin.requestId])
        center?.removePendingNotificationRequests(withIdentifiers: [origin.requestId])
    }

    private func clicked(slotId: UUID, pageId: String, nativeId: String) {
        showSlot(slotId)
        let deepLink = origins[nativeId]?.deepLink
        // The originating webview (the Slot's or one of its Child windows') must still belong to the Slot.
        guard let origin = origins[nativeId], let originWebView = origin.webView,
              slotForWebView(originWebView)?.id == slotId else {
            log.debug("Notification click: page gone, deep link \(deepLink?.absoluteString ?? "none", privacy: .public)")
            if let deepLink { openURL(slotId, deepLink) }
            return
        }
        // The shim checks the page id, so a reloaded page ignores the click.
        originWebView.callAsyncJavaScript(
            "return window.__slotbarNotificationClicked?.(id, pageId) ?? false",
            arguments: ["id": nativeId, "pageId": pageId], in: origin.frame, in: .page
        ) { [weak self] result in
            MainActor.assumeIsolated {
                if case .failure(let error) = result {
                    log.debug("onclick not delivered: \(error.localizedDescription, privacy: .public)")
                }
                let handled = if case .success(let value) = result { value as? String == "handled" } else { false }
                log.debug("Notification click: \(String(describing: result), privacy: .public), deep link \(deepLink?.absoluteString ?? "none", privacy: .public)")
                if !handled, let deepLink { self?.openURL(slotId, deepLink) }
            }
        }
    }
}

extension NotificationBridge: WKScriptMessageHandlerWithReply {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let body = message.body as? [String: Any], let op = body["op"] as? String else {
            return (nil, "Invalid message")
        }
        switch op {
        case "show":
            return (show(body, message: message), nil)
        case "close":
            if let id = body["id"] as? String { close(nativeId: id) }
            return (nil, nil)
        default:
            return (nil, "Unknown op")
        }
    }
}

extension NotificationBridge: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        let slotId = (content.userInfo["slotId"] as? String).flatMap(UUID.init(uuidString:))
        let silent = content.sound == nil
        guard let slotId else { return [.banner, .list, .sound] }
        return await MainActor.run {
            foregroundPresentation(originSlot: slotId, panelShowing: panelShowingSlot(), silent: silent)
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let slotId = (info["slotId"] as? String).flatMap(UUID.init(uuidString:)) else { return }
        let pageId = info["pageId"] as? String ?? ""
        let nativeId = info["nativeId"] as? String ?? ""
        await MainActor.run { clicked(slotId: slotId, pageId: pageId, nativeId: nativeId) }
    }
}
