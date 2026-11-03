import AppKit
import SwiftUI

/// Settings tabs, in window order.
enum SettingsTab: Int {
    case general, profiles, slots

    /// The Panel's "Open Settings" button: Slots, or Profiles while there is none to add a Slot to (SPEC 4.4).
    static func forEmptyState(settings: Settings) -> SettingsTab {
        settings.profiles.isEmpty ? .profiles : .slots
    }
}

/// The Settings window (SPEC 10): an `NSWindow` with toolbar-style tabs, each hosting a SwiftUI view.
/// A SwiftUI `TabView` outside a `Settings` scene renders segmented tabs, so `NSTabViewController` provides the toolbar.
/// Normal window level, so the floating Panel stays where it is.
@MainActor
final class SettingsWindowController {
    private let store: SettingsStore
    private let hotkey: Hotkey?
    private let openAtLogin: OpenAtLogin
    private let deleteProfile: (UUID) -> Void
    private let favicons: FaviconCache
    private var window: NSWindow?
    private var tabs: NSTabViewController?

    init(store: SettingsStore, hotkey: Hotkey?, openAtLogin: OpenAtLogin, favicons: FaviconCache,
         deleteProfile: @escaping (UUID) -> Void) {
        self.store = store
        self.hotkey = hotkey
        self.openAtLogin = openAtLogin
        self.deleteProfile = deleteProfile
        self.favicons = favicons
    }

    /// Opens the window on `tab`, or on the tab last shown when nil.
    func show(tab: SettingsTab? = nil) {
        let window = window ?? makeWindow()
        self.window = window
        if let tab { tabs?.selectedTabViewItemIndex = tab.rawValue }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        addTab(to: tabs, "General", systemImage: "gearshape",
               GeneralView(store: store, hotkey: hotkey, openAtLogin: openAtLogin))
        addTab(to: tabs, "Profiles", systemImage: "person.2",
               ProfilesView(store: store, deleteProfile: deleteProfile))
        addTab(to: tabs, "Slots", systemImage: "square.stack",
               SlotsView(store: store, favicons: favicons))
        self.tabs = tabs
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func addTab(to tabs: NSTabViewController, _ title: String, systemImage: String, _ view: some View) {
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.preferredContentSize]
        let item = NSTabViewItem(viewController: hosting)
        item.label = title
        item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        tabs.addTabViewItem(item)
    }
}
