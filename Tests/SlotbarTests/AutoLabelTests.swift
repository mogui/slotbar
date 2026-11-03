import Foundation
import Testing
@testable import Slotbar

@MainActor
@Suite struct AutoLabelTests {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("AutoLabelTests-\(UUID().uuidString)")

    @Test func nullLabelIsSetFromPageTitleAndProfileNameAndPersisted() {
        let store = SettingsStore(directory: directory)
        let mail = store.settings.slots[0]

        store.update { $0.applyAutoLabel(slotId: mail.id, pageTitle: "Inbox - Gmail") }

        let reloaded = SettingsStore(directory: directory)
        #expect(reloaded.settings.slots[0].label == "Inbox - Gmail - Default")
    }

    @Test func setLabelIsFrozen() {
        let store = SettingsStore(directory: directory)
        let mail = store.settings.slots[0]
        store.update { $0.applyAutoLabel(slotId: mail.id, pageTitle: "Gmail") }

        store.update { $0.applyAutoLabel(slotId: mail.id, pageTitle: "Inbox (3) - Gmail") }

        #expect(store.settings.slots[0].label == "Gmail - Default")
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankTitleLeavesLabelNullForTheNextLoad(title: String) {
        let store = SettingsStore(directory: directory)
        let mail = store.settings.slots[0]

        store.update { $0.applyAutoLabel(slotId: mail.id, pageTitle: title) }

        #expect(store.settings.slots[0].label == nil)
    }

    @Test func titleIsTrimmed() {
        let store = SettingsStore(directory: directory)
        let mail = store.settings.slots[0]

        store.update { $0.applyAutoLabel(slotId: mail.id, pageTitle: "  Calendar \n") }

        #expect(store.settings.slots[0].label == "Calendar - Default")
    }
}
