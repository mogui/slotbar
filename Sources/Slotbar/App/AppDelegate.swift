import AppKit

private let log = Log.logger("App")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsStore: SettingsStore?
    private var hotkey: Hotkey?
    private let profileStores = ProfileStores()
    private let notificationBridge = NotificationBridge()
    private var favicons: FaviconCache?
    /// One per Slot, in list order.
    private var slotControllers: [SlotController] = []
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let supportDirectory = URL.applicationSupportDirectory.appendingPathComponent("Slotbar")
        let store = SettingsStore(directory: supportDirectory)
        settingsStore = store
        let favicons = FaviconCache(directory: supportDirectory.appendingPathComponent("favicons"))
        self.favicons = favicons
        NSApp.mainMenu = Menus.mainMenu()
        let panel = PanelController(settingsStore: store, favicons: favicons)
        panel.onSlotAction = { [weak self] id, action in self?.perform(action, on: id) }
        panelController = panel
        hotkey = Hotkey { panel.toggle() }
        notificationBridge.slotForWebView = { [weak self] webView in
            self?.slotControllers.first { $0.owns(webView) }?.slot
        }
        UIDelegate.shared.openPopup = { [weak self] opener, configuration, action, features in
            self?.slotControllers.first { $0.owns(opener) }?
                .openPopup(from: opener, configuration: configuration, action: action, features: features)
        }
        UIDelegate.shared.closeWebView = { [weak self] webView in
            self?.slotControllers.first { $0.owns(webView) }?.webViewDidClose(webView)
        }
        notificationBridge.loadedSlots = { [weak self] in
            self?.slotControllers.filter { $0.webView != nil }.map(\.slot) ?? []
        }
        notificationBridge.panelShowingSlot = { panel.visibleSlot }
        notificationBridge.showSlot = { panel.show(slot: $0) }
        notificationBridge.requestAuthorizationIfNeeded()
        apply(store.settings)
        store.observe { [weak self] settings in self?.apply(settings) }
        let launchIds = slotsLoadedAtLaunch(store.settings.slots)
        for controller in slotControllers where launchIds.contains(controller.slot.id) {
            controller.load()
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let image = NSImage(named: "StatusIcon") {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeading
            }
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        refreshBadges()
        log.info("Launched")
    }

    /// Keeps one SlotController per Slot (reused by id), drops stale favicons and hands the controllers to the Panel.
    private func apply(_ settings: Settings) {
        let remaining = Set(settings.slots.map(\.id))
        notificationBridge.removeDelivered(slotIds: Set(slotControllers.map(\.slot.id)).subtracting(remaining))
        for controller in slotControllers where !remaining.contains(controller.slot.id) {
            controller.closeChildWindows()
        }
        guard let favicons else { return }
        for id in faviconCachesToDelete(old: slotControllers.map(\.slot), new: settings.slots) {
            favicons.remove(id)
        }
        slotControllers = settings.slots.map { slot in
            if let existing = slotControllers.first(where: { $0.slot.id == slot.id }) {
                existing.slot = slot
                return existing
            }
            let controller = SlotController(slot: slot, stores: profileStores,
                                            notifications: notificationBridge, favicons: favicons)
            controller.onUnlabeledLoad = { [weak self] id, title in
                guard let store = self?.settingsStore else { return }
                var labeled = store.settings
                labeled.applyAutoLabel(slotId: id, pageTitle: title)
                // A blank title changes nothing; skip the write and the observers.
                if labeled != store.settings { store.update { $0 = labeled } }
            }
            controller.onFaviconChange = { [weak self] _ in self?.panelController?.refreshRail() }
            controller.onUnreadChange = { [weak self] in self?.refreshBadges() }
            controller.onRoute = { [weak self] id, url in self?.openRouted(id, url) }
            controller.childWindowPlacement = { [weak self] width, height in
                self?.panelController?.childWindowFrame(width: width, height: height) ?? NSRect(x: 0, y: 0, width: 800, height: 700)
            }
            controller.onChildWindowClosed = { [weak self] in self?.panelController?.childWindowClosed() }
            return controller
        }
        for controller in slotControllers {
            controller.slots = settings.slots
            controller.profileName = settings.profiles.first { $0.id == controller.slot.profileId }?.name ?? ""
        }
        panelController?.update(settings: settings, controllers: slotControllers)
        refreshBadges()
    }

    /// Status item title = aggregated badge in monospaced digits; the Rail shows each Slot's own (SPEC 8.4).
    private func refreshBadges() {
        panelController?.refreshRail()
        guard let button = statusItem?.button else { return }
        let loaded = slotControllers.compactMap { controller in
            controller.unread.map {
                SlotUnread(profileId: controller.slot.profileId, homeHost: controller.slot.url.host() ?? "", state: $0)
            }
        }
        let badge = badgeText(BadgeAggregator.aggregate(loaded))
        let title = button.image == nil ? ["Slotbar", badge].compactMap { $0 }.joined(separator: " ") : badge ?? ""
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
        button.attributedTitle = NSAttributedString(string: title, attributes: [.font: font])
    }

    /// A routed link: load the target Slot at the URL (creating its webview when Unloaded) and show it (SPEC 6.2).
    private func openRouted(_ id: UUID, _ url: URL) {
        guard let controller = slotControllers.first(where: { $0.slot.id == id }) else { return }
        controller.load(at: url)
        panelController?.show(slot: id)
    }

    private func perform(_ action: SlotAction, on id: UUID) {
        if action == .toggleNotifications {
            settingsStore?.update { $0.toggleNotifications(slot: id) }
        } else {
            slotControllers.first { $0.slot.id == id }?.perform(action)
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            guard event.type != .leftMouseDown else { return }
            statusItem?.menu = Menus.statusMenu(hotkeyUnavailable: hotkey?.isUnavailable ?? false)
            sender.performClick(nil)
            statusItem?.menu = nil
        } else if event.type == .leftMouseDown {
            panelController?.statusMouseDown()
        } else {
            panelController?.statusMouseUp()
        }
    }

    @objc func showAbout(_ sender: Any?) {
        let link = "https://github.com/mogui/slotbar/releases"
        let credits = NSAttributedString(string: link, attributes: [.link: URL(string: link)!])
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    /// Placeholder window until the Settings tickets land.
    @objc func showSettings(_ sender: Any?) {
        let window = settingsWindow ?? {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: true)
            window.title = "Slotbar Settings"
            window.isReleasedWhenClosed = false
            let label = NSTextField(labelWithString: "Settings are not available yet.")
            label.frame = NSRect(x: 20, y: 90, width: 440, height: 20)
            label.alignment = .center
            window.contentView?.addSubview(label)
            window.center()
            settingsWindow = window
            return window
        }()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
