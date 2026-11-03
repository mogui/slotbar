import AppKit
import SwiftUI

/// The Settings window (SPEC 10): an `NSWindow` with toolbar-style tabs, each hosting a SwiftUI view.
/// A SwiftUI `TabView` outside a `Settings` scene renders segmented tabs, so `NSTabViewController` provides the toolbar.
/// Normal window level, so the floating Panel stays where it is.
@MainActor
final class SettingsWindowController {
    private let store: SettingsStore
    private let hotkey: Hotkey?
    private let openAtLogin: OpenAtLogin
    private var window: NSWindow?

    init(store: SettingsStore, hotkey: Hotkey?, openAtLogin: OpenAtLogin) {
        self.store = store
        self.hotkey = hotkey
        self.openAtLogin = openAtLogin
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        addTab(to: tabs, "General", systemImage: "gearshape",
               GeneralView(store: store, hotkey: hotkey, openAtLogin: openAtLogin))
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
