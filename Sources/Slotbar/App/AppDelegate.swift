import AppKit

private let log = Log.logger("App")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsStore: SettingsStore?
    private var hotkey: Hotkey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let supportDirectory = URL.applicationSupportDirectory.appendingPathComponent("Slotbar")
        let store = SettingsStore(directory: supportDirectory)
        settingsStore = store
        NSApp.mainMenu = Menus.mainMenu()
        let panel = PanelController(settingsStore: store)
        panelController = panel
        hotkey = Hotkey { panel.toggle() }

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
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        log.info("Launched")
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
        log.info("Settings requested; the Settings window is not built yet")
    }
}
