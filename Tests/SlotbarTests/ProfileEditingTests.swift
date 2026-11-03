import Foundation
import Testing
@testable import Slotbar

@Suite struct ProfileEditingTests {
    @Test func addedProfileIsNamedAfterItsPosition() {
        var settings = Settings.preset()
        settings.addProfile(id: UUID())
        #expect(settings.profiles.map(\.name) == ["Default", "Profile 2"])
    }

    @Test func addedProfileSkipsATakenName() {
        var settings = Settings.preset()
        settings.profiles[0].name = "Profile 2"
        settings.addProfile(id: UUID())
        #expect(settings.profiles.last?.name == "Profile 3")
    }

    @Test func addedProfileGetsTheNextPaletteColor() {
        var settings = Settings.preset()
        let id = UUID()
        settings.addProfile(id: id)
        #expect(settings.profiles.last == Profile(id: id, name: "Profile 2", color: "#AF52DE"))
    }

    @Test func slotsInProfileListsOnlyThatProfilesSlots() {
        var settings = Settings.preset()
        let other = UUID()
        settings.addProfile(id: other)
        settings.slots[1].profileId = other
        #expect(settings.slots(inProfile: other).map(\.url.absoluteString) == ["https://calendar.google.com/"])
    }

    @Test func deletingAProfileDeletesItsSlots() {
        var settings = Settings.preset()
        let other = UUID()
        settings.addProfile(id: other)
        settings.slots[1].profileId = other
        settings.deleteProfile(other)
        #expect(settings.profiles.map(\.name) == ["Default"])
        #expect(settings.slots.map(\.url.absoluteString) == ["https://mail.google.com/", "https://chat.google.com/"])
    }

    @Test func deletingTheLastProfileIsAllowed() {
        var settings = Settings.preset()
        settings.deleteProfile(settings.profiles[0].id)
        #expect(settings.profiles.isEmpty)
        #expect(settings.slots.isEmpty)
    }

    @Test func renameSetsTheName() {
        var settings = Settings.preset()
        settings.renameProfile(settings.profiles[0].id, to: "Work")
        #expect(settings.profiles[0].name == "Work")
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankRenameKeepsThePreviousName(name: String) {
        var settings = Settings.preset()
        settings.renameProfile(settings.profiles[0].id, to: name)
        #expect(settings.profiles[0].name == "Default")
    }
}
