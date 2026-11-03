import AppKit

/// Menus with nil targets: actions travel the responder chain to `AppDelegate` / `NSApplication`.
@MainActor
enum Menus {
    /// Hidden main menu (SPEC 9): never visible with `LSUIElement`, but provides the key equivalents.
    static func mainMenu() -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        appItem.submenu = appMenu()
        main.addItem(appItem)
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editItem.submenu = editMenu()
        main.addItem(editItem)
        return main
    }

    /// Status item right-click / Ctrl-click menu (SPEC 4.6).
    static func statusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings...", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(withTitle: "About Slotbar", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Slotbar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private static func appMenu() -> NSMenu {
        let menu = NSMenu(title: "Slotbar")
        menu.addItem(withTitle: "About Slotbar", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings...", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Slotbar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        return menu
    }
}
