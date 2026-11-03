import Testing
import AppKit
@testable import Slotbar

@MainActor
@Suite struct MenusTests {
    struct Entry: Equatable {
        let title: String
        let key: String
        let modifiers: NSEvent.ModifierFlags
        let action: Selector?
    }

    func entries(_ menu: NSMenu) -> [Entry] {
        menu.items.filter { !$0.isSeparatorItem }.map {
            Entry(title: $0.title, key: $0.keyEquivalent,
                  modifiers: $0.keyEquivalent.isEmpty ? [] : $0.keyEquivalentModifierMask, action: $0.action)
        }
    }

    @Test func hiddenMainMenuAppMenuOffersAboutSettingsAndQuit() throws {
        let appMenu = try #require(Menus.mainMenu().items.first?.submenu)
        #expect(entries(appMenu) == [
            Entry(title: "About Slotbar", key: "", modifiers: [], action: #selector(AppDelegate.showAbout(_:))),
            Entry(title: "Settings...", key: ",", modifiers: .command, action: #selector(AppDelegate.showSettings(_:))),
            Entry(title: "Quit Slotbar", key: "q", modifiers: .command, action: #selector(NSApplication.terminate(_:))),
        ])
    }

    @Test func hiddenMainMenuEditMenuOffersStandardEditingShortcuts() throws {
        let main = Menus.mainMenu()
        #expect(main.items.count == 2)
        let editItem = try #require(main.items.last)
        #expect(editItem.title == "Edit")
        let editMenu = try #require(editItem.submenu)
        #expect(entries(editMenu) == [
            Entry(title: "Undo", key: "z", modifiers: .command, action: Selector(("undo:"))),
            Entry(title: "Redo", key: "z", modifiers: [.command, .shift], action: Selector(("redo:"))),
            Entry(title: "Cut", key: "x", modifiers: .command, action: #selector(NSText.cut(_:))),
            Entry(title: "Copy", key: "c", modifiers: .command, action: #selector(NSText.copy(_:))),
            Entry(title: "Paste", key: "v", modifiers: .command, action: #selector(NSText.paste(_:))),
            Entry(title: "Select All", key: "a", modifiers: .command, action: #selector(NSText.selectAll(_:))),
        ])
    }

    @Test func statusMenuOffersSettingsAboutAndQuit() {
        #expect(entries(Menus.statusMenu()) == [
            Entry(title: "Settings...", key: ",", modifiers: .command, action: #selector(AppDelegate.showSettings(_:))),
            Entry(title: "About Slotbar", key: "", modifiers: [], action: #selector(AppDelegate.showAbout(_:))),
            Entry(title: "Quit Slotbar", key: "q", modifiers: .command, action: #selector(NSApplication.terminate(_:))),
        ])
    }

    @Test(arguments: [true, false])
    func slotMenuOffersActionsThenNotificationsCheckItem(notifications: Bool) {
        let menu = Menus.slotMenu(notifications: notifications)
        #expect(menu.items.map(\.isSeparatorItem) == [false, false, false, true, false])
        #expect(entries(menu) == [
            Entry(title: "Go home", key: "", modifiers: [], action: #selector(RailView.goHome(_:))),
            Entry(title: "Open current page in browser", key: "", modifiers: [], action: #selector(RailView.openInBrowser(_:))),
            Entry(title: "Reload", key: "", modifiers: [], action: #selector(RailView.reload(_:))),
            Entry(title: "Notifications", key: "", modifiers: [], action: #selector(RailView.toggleNotifications(_:))),
        ])
        #expect(menu.items.last?.state == (notifications ? .on : .off))
    }
}
