import AppKit

private let log = Log.logger("App")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsStore: SettingsStore?
    private let profileStores = ProfileStores()
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
        panelController = PanelController(favicons: favicons)
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
            } else {
                button.title = "Slotbar"
            }
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        log.info("Launched")
    }

    /// Keeps one SlotController per Slot (reused by id), drops stale favicons and hands the controllers to the Panel.
    private func apply(_ settings: Settings) {
        guard let favicons else { return }
        for id in faviconCachesToDelete(old: slotControllers.map(\.slot), new: settings.slots) {
            favicons.remove(id)
        }
        slotControllers = settings.slots.map { slot in
            if let existing = slotControllers.first(where: { $0.slot.id == slot.id }) {
                existing.slot = slot
                return existing
            }
            let controller = SlotController(slot: slot, stores: profileStores, favicons: favicons)
            controller.onUnlabeledLoad = { [weak self] id, title in
                guard let store = self?.settingsStore else { return }
                var labeled = store.settings
                labeled.applyAutoLabel(slotId: id, pageTitle: title)
                // A blank title changes nothing; skip the write and the observers.
                if labeled != store.settings { store.update { $0 = labeled } }
            }
            controller.onFaviconChange = { [weak self] _ in self?.panelController?.refreshRail() }
            return controller
        }
        panelController?.update(settings: settings, controllers: slotControllers)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem?.menu = Menus.statusMenu()
            sender.performClick(nil)
            statusItem?.menu = nil
        } else {
            panelController?.toggle()
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
