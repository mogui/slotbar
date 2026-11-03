import AppKit

private let log = Log.logger("App")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsStore: SettingsStore?
    private let profileStores = ProfileStores()
    private let notificationBridge = NotificationBridge()
    /// One per Slot, in list order.
    private var slotControllers: [SlotController] = []
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let supportDirectory = URL.applicationSupportDirectory.appendingPathComponent("Slotbar")
        let store = SettingsStore(directory: supportDirectory)
        settingsStore = store
        NSApp.mainMenu = Menus.mainMenu()
        let panel = PanelController()
        panelController = panel
        notificationBridge.slotForWebView = { [weak self] webView in
            self?.slotControllers.first { $0.webView === webView }?.slot
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

    /// Keeps one SlotController per Slot (reused by id) and hands them to the Panel.
    private func apply(_ settings: Settings) {
        let remaining = Set(settings.slots.map(\.id))
        notificationBridge.removeDelivered(slotIds: Set(slotControllers.map(\.slot.id)).subtracting(remaining))
        slotControllers = settings.slots.map { slot in
            if let existing = slotControllers.first(where: { $0.slot.id == slot.id }) {
                existing.slot = slot
                return existing
            }
            return SlotController(slot: slot, stores: profileStores, notifications: notificationBridge)
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
