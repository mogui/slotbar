import Foundation
import Testing
@testable import Slotbar

@Suite struct SlotURLInputTests {
    @Test func bareHostGetsHTTPS() {
        #expect(slotURL(from: "mail.google.com") == URL(string: "https://mail.google.com"))
    }

    @Test(arguments: ["https://mail.google.com/mail/u/1/", "http://intranet.example/"])
    func absoluteWebURLIsKept(input: String) {
        #expect(slotURL(from: input) == URL(string: input))
    }

    @Test func surroundingWhitespaceIsIgnored() {
        #expect(slotURL(from: "  https://chat.google.com/ \n") == URL(string: "https://chat.google.com/"))
    }

    @Test(arguments: ["", "   ", "ftp://example.com/", "mailto:a@b.com", "https://", "not a url", "file:///etc/hosts"])
    func otherInputIsRejected(input: String) {
        #expect(slotURL(from: input) == nil)
    }
}

@Suite struct SlotListEditingTests {
    @Test func addedSlotIsAppendedWithDefaults() {
        var settings = Settings.preset()
        let id = UUID(), profile = settings.profiles[0].id
        settings.addSlot(id: id, url: URL(string: "https://drive.google.com/")!, profileId: profile)
        #expect(settings.slots.count == 4)
        #expect(settings.slots.last == Slot(id: id, url: URL(string: "https://drive.google.com/")!, profileId: profile,
                                            label: nil, keepAlive: true, notifications: true))
    }

    @Test func reorderChangesWhichSlotCmdNShows() {
        var settings = Settings.preset()
        let chat = settings.slots[2].id
        settings.moveSlots(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(slotId(number: 1, in: settings.slots) == chat)
        #expect(settings.slots.map(\.url.absoluteString) == ["https://chat.google.com/", "https://mail.google.com/", "https://calendar.google.com/"])
    }

    @Test func draggingDownPlacesTheSlotBeforeTheDropOffset() {
        var settings = Settings.preset()
        settings.moveSlots(fromOffsets: IndexSet(integer: 0), toOffset: 2)
        #expect(settings.slots.map(\.url.absoluteString) == ["https://calendar.google.com/", "https://mail.google.com/", "https://chat.google.com/"])
    }

    @Test func labelIsSet() {
        var settings = Settings.preset()
        settings.setLabel(slot: settings.slots[0].id, to: "Work mail")
        #expect(settings.slots[0].label == "Work mail")
    }

    @Test(arguments: ["", "  ", "\n"])
    func clearingTheLabelSetsNull(text: String) {
        var settings = Settings.preset()
        settings.slots[0].label = "Inbox - Default"
        settings.setLabel(slot: settings.slots[0].id, to: text)
        #expect(settings.slots[0].label == nil)
    }

    @Test func deletingASlotRemovesOnlyThatSlot() {
        var settings = Settings.preset()
        settings.deleteSlot(settings.slots[1].id)
        #expect(settings.slots.map(\.url.absoluteString) == ["https://mail.google.com/", "https://chat.google.com/"])
    }

    @Test func urlEditKeepsLabelAndPosition() {
        var settings = Settings.preset()
        settings.slots[1].label = "Calendar - Default"
        let id = settings.slots[1].id
        settings.setURL(slot: id, to: URL(string: "https://calendar.google.com/calendar/u/1/")!)
        #expect(settings.slots[1].id == id)
        #expect(settings.slots[1].label == "Calendar - Default")
        #expect(settings.slots[1].url.absoluteString == "https://calendar.google.com/calendar/u/1/")
    }

    @Test func profileEditKeepsLabelAndPosition() {
        var settings = Settings.preset()
        let other = UUID()
        settings.addProfile(id: other)
        settings.slots[2].label = "Chat - Default"
        let id = settings.slots[2].id
        settings.setProfile(slot: id, to: other)
        #expect(settings.slots[2].id == id)
        #expect(settings.slots[2].label == "Chat - Default")
        #expect(settings.slots[2].profileId == other)
    }
}

@Suite struct EmptyStateTabTests {
    @Test func opensSlotsWhenAProfileExists() {
        #expect(SettingsTab.forEmptyState(settings: Settings.preset()) == .slots)
    }

    @Test func opensProfilesWhenThereAreNoProfiles() {
        var settings = Settings.preset()
        settings.deleteProfile(settings.profiles[0].id)
        #expect(SettingsTab.forEmptyState(settings: settings) == .profiles)
    }
}
