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
    private var settingsWindow: SettingsWindowController?
    private var memoryPressure: DispatchSourceMemoryPressure?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Failed store removals are retried before any webview exists (SPEC 3.4).
        Task {
            await profileStores.retryPendingDeletions()
            launch()
        }
    }

    private func launch() {
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
        let openAtLogin = OpenAtLogin(service: MainAppLoginItem(), store: store)
        openAtLogin.healAtLaunch()
        settingsWindow = SettingsWindowController(store: store, hotkey: hotkey, openAtLogin: openAtLogin,
                                                  favicons: favicons, deleteProfile: { [weak self] id in self?.deleteProfile(id) })
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
        watchMemoryPressure()
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
        warnIfOutsideApplications()
    }

    /// Keeps one SlotController per Slot (reused by id), drops stale favicons and hands the controllers to the Panel.
    private func apply(_ settings: Settings) {
        let remaining = Set(settings.slots.map(\.id))
        for controller in slotControllers where !remaining.contains(controller.slot.id) {
            controller.close()
        }
        notificationBridge.removeDelivered(slotIds: Set(slotControllers.map(\.slot.id)).subtracting(remaining))
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
            controller.onContentChange = { [weak self] in self?.panelController?.slotContentChanged(slot.id) }
            return controller
        }
        for controller in slotControllers {
            controller.slots = settings.slots
            controller.profileName = settings.profiles.first { $0.id == controller.slot.profileId }?.name ?? ""
        }
        panelController?.update(settings: settings, controllers: slotControllers)
        refreshBadges()
    }

    /// On a warning or critical event, Slots in their grace period unload at once (SPEC 6.2).
    private func watchMemoryPressure() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                log.info("Memory pressure")
                self?.slotControllers.forEach { $0.memoryPressure() }
            }
        }
        source.resume()
        memoryPressure = source
    }

    /// Status item title = aggregated badge in monospaced digits; the Rail shows each Slot's own (SPEC 8.4).
    private func refreshBadges() {
        panelController?.refreshRail()
        guard let button = statusItem?.button else { return }
        let loaded = slotControllers.compactMap { controller in
            controller.unread.map {
                SlotUnread(profileId: controller.slot.profileId, homeHost: controller.slot.homeHost ?? "", state: $0)
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

    /// Cascade (SPEC 3.4, 5): the Settings write closes the Profile's Slots and drops their notifications
    /// and favicon caches in `apply`, then the data store is removed (or queued for the next launch).
    private func deleteProfile(_ id: UUID) {
        settingsStore?.update { $0.deleteProfile(id) }
        Task { await profileStores.delete(id) }
    }

    private func perform(_ action: SlotAction, on id: UUID) {
        slotControllers.first { $0.slot.id == id }?.perform(action)
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

    @objc func showSettings(_ sender: Any?) {
        settingsWindow?.show()
    }

    /// The Panel's empty-state button (SPEC 4.4).
    @objc func showSettingsForEmptyState(_ sender: Any?) {
        guard let settings = settingsStore?.settings else { return }
        settingsWindow?.show(tab: .forEmptyState(settings: settings))
    }

    /// Shown at every launch while the app runs translocated or outside Applications (SPEC 12.5).
    private func warnIfOutsideApplications() {
        guard LocationGuard.needsMove(bundlePath: Bundle.main.bundlePath,
                                      homeDirectory: FileManager.default.homeDirectoryForCurrentUser.path) else { return }
        log.info("Running outside Applications: \(Bundle.main.bundlePath, privacy: .public)")
        let alert = NSAlert()
        alert.messageText = "Move Slotbar to Applications"
        alert.informativeText = "Notifications need Slotbar to run from the Applications folder. Quit Slotbar, move it to Applications and open it again."
        alert.addButton(withTitle: "OK")
        NSApp.activate()
        alert.runModal()
    }
}
