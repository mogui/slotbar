import AppKit
import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load (SPEC 6.2), routes its navigations (SPEC 7)
/// and keeps its favicon and auto-label up to date (SPEC 3.1, 4.4).
@MainActor
final class SlotController: NSObject, WKNavigationDelegate {
    var slot: Slot
    /// All Slots in list order, for routing to a same-Profile Slot.
    var slots: [Slot] = []
    /// Show the Slot with this id and load the URL there.
    var onRoute: ((UUID, URL) -> Void)?
    private let stores: ProfileStores
    private let notifications: NotificationBridge
    private let favicons: FaviconCache
    private(set) var webView: WKWebView?
    /// Icon link last fetched in this session.
    private var lastIconURL: URL?
    /// Called when the loaded Slot's Unread state changes.
    var onUnreadChange: (() -> Void)?
    private var unreadMonitor: UnreadMonitor?
    private var signInMode = SignInMode()
    /// The next main-frame request is the Slot's own load (starting, reopen or routed URL).
    private var nextLoadIsOwn = false
    /// A main-frame navigation has started and not committed or failed yet.
    private var mainFrameProvisional = false

    var isInSignInMode: Bool { signInMode.isActive(at: Date()) }

    /// Open Child windows (SPEC 4.7), oldest first.
    private(set) var childWindows: [ChildWindowController] = []
    /// Shown in Child window titles.
    var profileName = "" {
        didSet { childWindows.forEach { $0.profileName = profileName } }
    }
    /// Frame for a new Child window from the `window.open` width and height (Panel's screen, off the Panel).
    var childWindowPlacement: ((_ width: CGFloat?, _ height: CGFloat?) -> NSRect)?
    /// A Child window closed (Cmd+W, `window.close()`, its crash, or the Slot closing it).
    var onChildWindowClosed: (() -> Void)?

    /// Page title of a completed main-frame load while the Slot's label is null.
    var onUnlabeledLoad: ((_ slotId: UUID, _ pageTitle: String) -> Void)?
    /// A new favicon was cached.
    var onFaviconChange: ((_ slotId: UUID) -> Void)?

    init(slot: Slot, stores: ProfileStores, notifications: NotificationBridge, favicons: FaviconCache) {
        self.slot = slot
        self.stores = stores
        self.notifications = notifications
        self.favicons = favicons
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
            let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId),
                                                     notifications: notifications,
                                                     faviconHandler: WeakScriptHandler(self))
            webView.navigationDelegate = self
            let monitor = UnreadMonitor(homeHost: slot.url.host() ?? "")
            monitor.onChange = { [weak self] in self?.onUnreadChange?() }
            monitor.attach(to: webView)
            unreadMonitor = monitor
            self.webView = webView
            log.debug("Loading Slot \(self.slot.id, privacy: .public)")
            return webView
        }()
        nextLoadIsOwn = true
        webView.load(URLRequest(url: url))
        return webView
    }

    /// Destroys the webview of a deleted Slot so its Profile's data store is no longer attached (SPEC 3.4, 5).
    func close() {
        guard let webView else { return }
        webView.stopLoading()
        webView.removeFromSuperview()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        self.webView = nil
        unreadMonitor = nil
        log.debug("Closed Slot \(self.slot.id, privacy: .public)")
    }

    /// Go home, open current page in browser, reload (SPEC 7.5). Loads the Slot first if needed.
    func perform(_ action: SlotAction) {
        switch action {
        case .goHome:
            load(at: slot.url)
        case .openInBrowser:
            NSWorkspace.shared.open(webView?.url ?? slot.url)
        case .reload:
            if let webView { webView.reload() } else { load() }
        case .toggleNotifications:
            break
        }
    }

    /// The Slot's webview or one of its Child windows' webviews.
    func owns(_ webView: WKWebView) -> Bool {
        webView === self.webView || childWindows.contains { $0.webView === webView }
    }

    /// A popup from the Slot or one of its Child windows (SPEC 7.3): returns the Child window's webview, or nil.
    func openPopup(from opener: WKWebView, configuration: WKWebViewConfiguration,
                   action: WKNavigationAction, features: WKWindowFeatures) -> WKWebView? {
        let route = popupRoute(url: action.request.url, openerURL: opener.url, from: slot, slots: slots,
                               inSignInMode: isInSignInMode,
                               opensOutside: action.modifierFlags.contains(.command) || action.buttonNumber == 1)
        #if DEBUG
        log.debug("Popup \(action.request.url?.absoluteString ?? "", privacy: .public) from Slot \(self.slot.id, privacy: .public): \(String(describing: route), privacy: .public)")
        #endif
        switch route {
        case .childWindow, .signIn:
            if route == .signIn { signInMode.enter(at: Date()) }
            let width = features.width.map { CGFloat($0.doubleValue) }
            let height = features.height.map { CGFloat($0.doubleValue) }
            let frame = childWindowPlacement?(width, height) ?? NSRect(x: 0, y: 0, width: 800, height: 700)
            let child = ChildWindowController(configuration: configuration, frame: frame, profileName: profileName)
            child.onClose = { [weak self] child in
                self?.childWindows.removeAll { $0 === child }
                self?.onChildWindowClosed?()
            }
            childWindows.append(child)
            child.show()
            return child.webView
        case .slot(let id, let target):
            onRoute?(id, target)
        case .browser(let target):
            NSWorkspace.shared.open(target)
        case .discard:
            break
        }
        return nil
    }

    /// `window.close()` from a Child window's page closes it; the Slot's own webview ignores it.
    func webViewDidClose(_ webView: WKWebView) {
        childWindows.first { $0.webView === webView }?.close()
    }

    /// Slot unloaded, crashed or deleted (SPEC 4.7).
    func closeChildWindows() {
        childWindows.forEach { $0.close() }
    }

    /// The Slot's Unread state while loaded; nil when Unloaded (contributes nothing).
    var unread: UnreadState? {
        webView == nil ? nil : unreadMonitor?.state
    }

    fileprivate func iconLinkReported(_ body: Any) {
        let reported = (body as? String).flatMap(URL.init(string:))
        guard let iconURL = faviconURL(reported: reported, slotURL: slot.url),
              shouldFetchFavicon(slotURL: slot.url, lastIconURL: lastIconURL, iconURL: iconURL,
                                 hasCachedIcon: favicons.hasIcon(for: slot.id)) else { return }
        lastIconURL = iconURL
        let slot = slot
        let store = stores.store(for: slot.profileId)
        Task { [weak self] in
            guard let data = await Self.fetch(iconURL, store: store) else { return }
            // Dropped if the Slot was deleted or moved to another URL or Profile meanwhile.
            guard let self, self.slot.url == slot.url, self.slot.profileId == slot.profileId else { return }
            self.favicons.store(imageData: data, for: slot.id)
            if self.favicons.hasIcon(for: slot.id) { self.onFaviconChange?(slot.id) }
        }
    }

    /// Fetches with the Profile's cookies and the Slotbar user agent, so the icon comes "through the Slot's data store".
    private static func fetch(_ url: URL, store: WKWebsiteDataStore) async -> Data? {
        let cookies = await store.httpCookieStore.allCookies()
        let configuration = URLSessionConfiguration.ephemeral
        cookies.forEach { configuration.httpCookieStorage?.setCookie($0) }
        configuration.httpAdditionalHeaders = ["User-Agent": WebViewFactory.userAgent]
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            log.debug("Favicon fetch failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: WKNavigationDelegate - routing, downloads via DownloadManager (SPEC 7.4), auto-label

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        if action.shouldPerformDownload { return decisionHandler(.download) }
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard slot.label == nil else { return }
        onUnlabeledLoad?(slot.id, webView.title ?? "")
    }
}

/// `WKUserContentController` retains its handlers; this breaks the SlotController -> webview -> handler cycle.
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var controller: SlotController?

    init(_ controller: SlotController) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated {
            // Child windows share this user content controller; only the Slot's own page counts.
            guard message.frameInfo.isMainFrame, let controller, message.webView === controller.webView else { return }
            controller.iconLinkReported(message.body)
        }
    }
}
