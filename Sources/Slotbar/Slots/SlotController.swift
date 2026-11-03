import AppKit
import WebKit

private let log = Log.logger("Slots")

/// Owns one Slot's webview, created on first load and released by the lifecycle (SPEC 6), routes its
/// navigations (SPEC 7) and keeps its favicon and auto-label up to date (SPEC 3.1, 4.4).
@MainActor
final class SlotController: NSObject, WKNavigationDelegate {
    var slot: Slot {
        didSet {
            favicon.slot = slot
            if !slot.hasSameStart(as: oldValue) { startChanged() }
            guard slot.keepAlive != oldValue.keepAlive else { return }
            if lifecycle.setKeepAlive(slot.keepAlive, at: Date()) { load() }
        }
    }
    /// All Slots in list order, for routing to a same-Profile Slot.
    var slots: [Slot] = []
    /// Show the Slot with this id and load the URL there.
    var onRoute: ((UUID, URL) -> Void)?
    private let stores: ProfileStores
    private let notifications: NotificationBridge
    private let favicon: FaviconFetcher
    private(set) var webView: WKWebView?
    /// Called when the loaded Slot's Unread state changes.
    var onUnreadChange: (() -> Void)?
    private var unreadMonitor: UnreadMonitor?
    private var signInMode = SignInMode()
    private var lifecycle: SlotLifecycle {
        didSet { scheduleGraceTimer() }
    }
    private var graceTimer: Timer?
    /// Last main-frame URL seen, kept after unload until quit.
    private var lastURL: URL?
    /// Unread state when the crash placeholder replaced the webview.
    private var lastUnread: UnreadState = .none
    private lazy var crashPlaceholder = makeCrashPlaceholder()
    /// The view the Panel shows for this Slot changed by itself (crash placeholder entered or left).
    var onContentChange: (() -> Void)?
    /// The next main-frame request is the Slot's own load (starting, reopen or routed URL).
    private var nextLoadIsOwn = false
    /// A main-frame navigation has started and not committed or failed yet.
    private var mainFrameProvisional = false

    var isInSignInMode: Bool { signInMode.isActive(at: Date()) }

    /// Popups that stay in the app (SPEC 4.7).
    let childWindows = ChildWindows()
    /// A Child window closed (Cmd+W, `window.close()`, its crash, or the Slot closing it).
    var onChildWindowClosed: (() -> Void)?

    /// Page title of a completed main-frame load while the Slot's label is null.
    var onUnlabeledLoad: ((_ slotId: UUID, _ pageTitle: String) -> Void)?
    /// A new favicon was cached.
    var onFaviconChange: ((_ slotId: UUID) -> Void)? {
        get { favicon.onChange }
        set { favicon.onChange = newValue }
    }

    init(slot: Slot, stores: ProfileStores, notifications: NotificationBridge, favicons: FaviconCache) {
        self.slot = slot
        self.stores = stores
        self.notifications = notifications
        favicon = FaviconFetcher(slot: slot, stores: stores, favicons: favicons)
        lifecycle = SlotLifecycle(keepAlive: slot.keepAlive)
        super.init()
        childWindows.onClose = { [weak self] in
            guard let self else { return }
            self.lifecycle.setChildWindowCount(self.childWindows.count, at: Date())
            self.onChildWindowClosed?()
        }
        // A sign-in popup that lands on the Home host ends Sign-in mode, like the Slot's own commit (SPEC 7.2).
        childWindows.onCommit = { [weak self] url in
            guard let self else { return }
            self.signInMode.didCommit(url, homeHost: self.slot.homeHost)
        }
    }

    var reopenURL: URL { Slotbar.reopenURL(lastURL: webView?.url ?? lastURL, slot: slot) }

    /// The Panel shows the Slot (SPEC 6.1); a hidden non-keep-alive Slot runs the grace timer.
    func setShown(_ shown: Bool) {
        if lifecycle.isShown != shown { lifecycle.setShown(shown, at: Date()) }
    }

    /// What the Panel shows: the crash placeholder, else the webview (loading the Slot if Unloaded).
    func contentView() -> NSView {
        lifecycle.state == .crashPlaceholder ? crashPlaceholder : load()
    }

    /// Loads the Slot at its reopen URL if it has no webview yet.
    @discardableResult
    func load() -> WKWebView {
        if let webView { return webView }
        return load(at: reopenURL)
    }

    /// Loads `url` (never routed): creates the webview when Unloaded or in the crash placeholder, else navigates in place.
    @discardableResult
    func load(at url: URL) -> WKWebView {
        let webView = self.webView ?? {
            let webView = WebViewFactory.makeWebView(store: stores.store(for: slot.profileId),
                                                     notifications: notifications,
                                                     faviconHandler: WeakScriptHandler(self))
            webView.navigationDelegate = self
            let monitor = UnreadMonitor(homeHost: slot.homeHost ?? "")
            monitor.onChange = { [weak self] in self?.onUnreadChange?() }
            monitor.attach(to: webView)
            unreadMonitor = monitor
            self.webView = webView
            log.debug("Loading Slot \(self.slot.id, privacy: .public)")
            let leavesPlaceholder = lifecycle.state == .crashPlaceholder
            lifecycle.loaded(at: Date())
            if leavesPlaceholder { onContentChange?() }
            return webView
        }()
        nextLoadIsOwn = true
        webView.load(URLRequest(url: url))
        return webView
    }

    /// Destroys the webview and Child windows (Slot deleted or unloaded) so its page process ends and its
    /// Profile's data store is no longer attached (SPEC 3.4, 5, 6.3). Favicon and reopen URL are kept.
    func close() {
        releaseWebView()
        lifecycle.unloaded()
    }

    /// URL or Profile edited in Settings (SPEC 10.3): Child windows close, the reopen URL is cleared and
    /// Sign-in mode ends, so routing uses the new Home host at once (`AppDelegate.apply` deletes the favicon). A loaded Slot gets a new webview at the new URL, on the
    /// new Profile's store and with the Unread adapter for the new Home host; an Unloaded one loads it on next open.
    private func startChanged() {
        let wasLoaded = webView != nil
        releaseWebView()
        lastURL = nil
        signInMode = SignInMode()
        guard wasLoaded else { return }
        load(at: slot.url)
        onUnreadChange?()
    }

    /// Memory pressure (SPEC 6.2): unloads the Slot when it is in its grace period.
    func memoryPressure() {
        guard lifecycle.memoryPressure() else { return }
        log.info("Memory pressure: unloading Slot \(self.slot.id, privacy: .public)")
        unload()
    }

    private func unload() {
        close()
        onUnreadChange?()
    }

    private func scheduleGraceTimer() {
        guard graceTimer?.fireDate != lifecycle.graceDeadline else { return }
        graceTimer?.invalidate()
        graceTimer = nil
        guard let deadline = lifecycle.graceDeadline else { return }
        let timer = Timer(fire: deadline, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.lifecycle.expireGrace(at: Date()) else { return }
                log.debug("Grace period over: unloading Slot \(self.slot.id, privacy: .public)")
                self.unload()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        graceTimer = timer
    }

    private func releaseWebView() {
        childWindows.closeAll()
        guard let webView else { return }
        lastURL = webView.url ?? lastURL
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
            if lifecycle.state == .crashPlaceholder {
                load(at: reopenURL)
            } else if let webView {
                webView.reload()
            } else {
                load()
            }
        }
    }

    /// The Slot's webview or one of its Child windows' webviews.
    func owns(_ webView: WKWebView) -> Bool {
        webView === self.webView || childWindows.contains(webView)
    }

    /// A popup from the Slot or one of its Child windows (SPEC 7.3): returns the Child window's webview, or nil.
    func openPopup(from opener: WKWebView, configuration: WKWebViewConfiguration,
                   action: WKNavigationAction, features: WKWindowFeatures) -> WKWebView? {
        let route = popupRoute(url: action.request.url, openerURL: opener.url, from: slot, slots: slots,
                               inSignInMode: isInSignInMode,
                               opensOutside: action.opensOutside)
        #if DEBUG
        log.debug("Popup \(action.request.url?.absoluteString ?? "", privacy: .public) from Slot \(self.slot.id, privacy: .public): \(String(describing: route), privacy: .public)")
        #endif
        switch route {
        case .childWindow, .signIn:
            if route == .signIn { signInMode.enter(at: Date()) }
            let webView = childWindows.open(configuration: configuration, features: features)
            lifecycle.setChildWindowCount(childWindows.count, at: Date())
            return webView
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
        childWindows.close(webView)
    }

    /// The Slot's Unread state while loaded; nil when Unloaded (contributes nothing); "count unknown"
    /// in the crash placeholder when something was unread (SPEC 6.4).
    var unread: UnreadState? {
        if lifecycle.state == .crashPlaceholder { return crashPlaceholderUnread(last: lastUnread) }
        return webView == nil ? nil : unreadMonitor?.state
    }

    /// Native view replacing the webview after the crash cap (SPEC 6.4).
    private func makeCrashPlaceholder() -> NSView {
        let label = NSTextField(labelWithString: "This Slot stopped after repeated crashes.")
        label.textColor = .secondaryLabelColor
        let button = NSButton(title: "Reload", target: self, action: #selector(reloadFromPlaceholder(_:)))
        let stack = NSStackView(views: [label, button])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let view = NSView()
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }

    @objc private func reloadFromPlaceholder(_ sender: Any?) {
        load(at: reopenURL)
    }

    fileprivate func faviconLinkReported(_ body: Any) {
        favicon.iconLinkReported(body)
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
                                        opensOutside: action.opensOutside)
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
        if let url = webView.url { signInMode.didCommit(url, homeHost: slot.homeHost) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        mainFrameProvisional = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        mainFrameProvisional = false
    }

    /// Page crash (SPEC 6.4); Child window crashes go to their own controller and never count here.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard webView === self.webView else { return }
        let state = unreadMonitor?.state ?? .none
        let response = lifecycle.crashed(at: Date())
        log.error("Slot \(self.slot.id, privacy: .public) page crashed: \(String(describing: response), privacy: .public)")
        switch response {
        case .reload:
            childWindows.closeAll()
            load(at: reopenURL)
        case .unload:
            unload()
        case .placeholder:
            lastUnread = state
            releaseWebView()
            onUnreadChange?()
            onContentChange?()
        }
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
            controller.faviconLinkReported(message.body)
        }
    }
}

extension WKNavigationAction {
    /// Cmd-click or middle-click (SPEC 7.1). WebKit reports a button mask: left 1, right 2, middle 4.
    var opensOutside: Bool { modifierFlags.contains(.command) || buttonNumber == 4 }
}
