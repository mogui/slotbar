import Foundation
import Testing
@testable import Slotbar

@Suite struct RailItemsTests {
    static let work = Profile(id: UUID(), name: "Work", color: "#AF52DE")
    static let home = Profile(id: UUID(), name: "Home", color: "#34C759")

    static func slot(_ url: String, _ profile: Profile, label: String? = nil) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile.id, label: label, keepAlive: true, notifications: true)
    }

    static func settings(_ slots: [Slot]) -> Settings {
        var s = Settings.preset()
        s.profiles = [work, home]
        s.slots = slots
        return s
    }

    @Test func tooltipShowsLabelAndCommandShortcut() {
        let mail = Self.slot("https://mail.google.com/", Self.work, label: "Gmail - Work")
        let items = railItems(settings: Self.settings([mail]), activeView: nil)
        #expect(items.map(\.tooltip) == ["Gmail - Work  ⌘1"])
    }

    @Test func tooltipShowsHomeHostWhileLabelIsNull() {
        let mail = Self.slot("https://mail.google.com/", Self.work)
        let items = railItems(settings: Self.settings([mail]), activeView: nil)
        #expect(items.map(\.tooltip) == ["mail.google.com  ⌘1"])
    }

    @Test func slotsAfterTheNinthShowLabelOnly() {
        let slots = (1...10).map { Self.slot("https://example.com/", Self.work, label: "S\($0)") }
        let items = railItems(settings: Self.settings(slots), activeView: nil)
        #expect(items[8].tooltip == "S9  ⌘9")
        #expect(items[9].tooltip == "S10")
    }

    @Test func itemsFollowListOrderWithTheirProfileColor() {
        let a = Self.slot("https://mail.google.com/", Self.home)
        let b = Self.slot("https://chat.google.com/", Self.work)
        let items = railItems(settings: Self.settings([a, b]), activeView: nil)
        #expect(items.map(\.view) == [.slot(a.id), .slot(b.id)])
        #expect(items.map(\.color) == [ProfileColor(red: 0x34, green: 0xC7, blue: 0x59),
                                       ProfileColor(red: 0xAF, green: 0x52, blue: 0xDE)])
    }

    @Test func onlyTheActiveSlotIsHighlighted() {
        let a = Self.slot("https://mail.google.com/", Self.work)
        let b = Self.slot("https://chat.google.com/", Self.work)
        let items = railItems(settings: Self.settings([a, b]), activeView: .slot(b.id))
        #expect(items.map(\.isActive) == [false, true])
    }

    @Test func eachItemShowsItsOwnSlotsBadgeWithoutCrossSlotDedup() {
        let a = Self.slot("https://mail.google.com/", Self.work)
        let b = Self.slot("https://mail.google.com/", Self.work)
        let c = Self.slot("https://chat.google.com/", Self.work)
        let d = Self.slot("https://calendar.google.com/", Self.work)
        let items = railItems(settings: Self.settings([a, b, c, d]), activeView: nil,
                              unread: [a.id: .count(3), b.id: .count(120), c.id: .unknown])
        #expect(items.map(\.badge) == ["3", "99+", "\u{25CF}", nil])
    }

    static func withTerminal(_ slots: [Slot]) -> Settings {
        var s = settings(slots)
        s.terminal.enabled = true
        return s
    }

    @Test func terminalItemIsAbsentWhileTheTerminalIsOff() {
        let a = Self.slot("https://mail.google.com/", Self.work)
        let items = railItems(settings: Self.settings([a]), activeView: nil)
        #expect(items.map(\.view) == [.slot(a.id)])
    }

    @Test func terminalItemComesAfterEverySlotWhileEnabled() {
        let a = Self.slot("https://mail.google.com/", Self.work)
        let b = Self.slot("https://chat.google.com/", Self.home)
        let items = railItems(settings: Self.withTerminal([a, b]), activeView: nil)
        #expect(items.map(\.view) == [.slot(a.id), .slot(b.id), .terminal])
    }

    @Test func terminalItemHasNoProfileColorNoBadgeAndATerminalTooltip() {
        let items = railItems(settings: Self.withTerminal([]), activeView: nil)
        #expect(items == [RailItem(view: .terminal, tooltip: "Terminal", color: nil,
                                   isActive: false, notifications: false, badge: nil)])
    }

    @Test func terminalItemIsHighlightedWhenTheTerminalIsTheActiveView() {
        let a = Self.slot("https://mail.google.com/", Self.work)
        let items = railItems(settings: Self.withTerminal([a]), activeView: .terminal)
        #expect(items.map(\.isActive) == [false, true])
    }

    @Test func terminalDoesNotTakeACommandNumber() {
        let slots = (1...9).map { Self.slot("https://example.com/", Self.work, label: "S\($0)") }
        let items = railItems(settings: Self.withTerminal(slots), activeView: nil)
        #expect(items[8].tooltip == "S9  ⌘9")
        #expect(items[9].tooltip == "Terminal")
    }
}
