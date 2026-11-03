import Foundation
import Testing
@testable import Slotbar

@Suite struct SlotSelectionTests {
    static let profile = UUID()
    static func slot(_ url: String, keepAlive: Bool = true) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile, label: nil, keepAlive: keepAlive, notifications: true)
    }

    let mail = slot("https://mail.google.com/")
    let calendar = slot("https://calendar.google.com/", keepAlive: false)
    let chat = slot("https://chat.google.com/")

    @Test func firstShowUsesSlot1() {
        #expect(slotToShow(slots: [mail, calendar, chat], lastActive: nil) == mail.id)
    }

    @Test func showRestoresLastActiveSlot() {
        #expect(slotToShow(slots: [mail, calendar, chat], lastActive: chat.id) == chat.id)
    }

    @Test func deletedLastActiveSlotFallsBackToSlot1() {
        #expect(slotToShow(slots: [mail, calendar], lastActive: chat.id) == mail.id)
    }

    @Test func noSlotsShowsNothing() {
        #expect(slotToShow(slots: [], lastActive: chat.id) == nil)
    }

    @Test func launchLoadsKeptAliveSlotsInListOrder() {
        #expect(slotsLoadedAtLaunch([mail, calendar, chat]) == [mail.id, chat.id])
    }
}
