import AppKit

private let log = Log.logger("App")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsStore: SettingsStore?
    private let profileStores = ProfileStores()
    /// One per Slot, in list order.
    private var slotControllers: [SlotController] = []
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let supportDirectory = URL.applicationSupportDirectory.appendingPathComponent("Slotbar")
        let store = SettingsStore(directory: supportDirectory)
        settingsStore = store
        NSApp.mainMenu = Menus.mainMenu()
        panelController = PanelController()
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
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        refreshBadges()
        log.info("Launched")
    }

    /// Keeps one SlotController per Slot (reused by id) and hands them to the Panel.
    private func apply(_ settings: Settings) {
        slotControllers = settings.slots.map { slot in
            if let existing = slotControllers.first(where: { $0.slot.id == slot.id }) {
                existing.slot = slot
                return existing
            }
            let controller = SlotController(slot: slot, stores: profileStores)
            controller.onUnreadChange = { [weak self] in self?.refreshBadges() }
            return controller
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
