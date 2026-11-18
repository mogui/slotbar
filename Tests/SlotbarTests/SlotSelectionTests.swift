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
        #expect(viewToShow(slots: [mail, calendar, chat], lastActive: nil, terminalEnabled: false) == .slot(mail.id))
    }

    @Test func showRestoresLastActiveSlot() {
        #expect(viewToShow(slots: [mail, calendar, chat], lastActive: .slot(chat.id), terminalEnabled: false) == .slot(chat.id))
    }

    @Test func deletedLastActiveSlotFallsBackToSlot1() {
        #expect(viewToShow(slots: [mail, calendar], lastActive: .slot(chat.id), terminalEnabled: true) == .slot(mail.id))
    }

    @Test func noSlotsShowsNothing() {
        #expect(viewToShow(slots: [], lastActive: .slot(chat.id), terminalEnabled: false) == nil)
    }

    @Test func showRestoresTheTerminalWhileItIsEnabled() {
        #expect(viewToShow(slots: [mail, chat], lastActive: .terminal, terminalEnabled: true) == .terminal)
    }

    @Test func terminalTurnedOffFallsBackToSlot1() {
        #expect(viewToShow(slots: [mail, chat], lastActive: .terminal, terminalEnabled: false) == .slot(mail.id))
    }

    @Test func terminalTurnedOffWithNoSlotsShowsNothing() {
        #expect(viewToShow(slots: [], lastActive: .terminal, terminalEnabled: false) == nil)
    }

    @Test func terminalStaysShownWithNoSlots() {
        #expect(viewToShow(slots: [], lastActive: .terminal, terminalEnabled: true) == .terminal)
    }

    @Test func launchLoadsKeptAliveSlotsInListOrder() {
        #expect(slotsLoadedAtLaunch([mail, calendar, chat]) == [mail.id, chat.id])
    }

    @Test func slotNumberPicksSlotInListOrder() {
        #expect(slotId(number: 2, in: [mail, calendar, chat]) == calendar.id)
    }

    @Test func missingSlotNumberIsNoOp() {
        #expect(slotId(number: 4, in: [mail, calendar, chat]) == nil)
        #expect(slotId(number: 1, in: []) == nil)
    }
}
