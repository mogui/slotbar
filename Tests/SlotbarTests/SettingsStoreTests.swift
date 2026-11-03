import Foundation
import Testing
@testable import Slotbar

@MainActor
@Suite struct SettingsStoreTests {
    let directory: URL
    var settingsFile: URL { directory.appendingPathComponent("settings.json") }

    init() {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsStoreTests-\(UUID().uuidString)")
            .appendingPathComponent("Slotbar")
    }

    func writeFile(_ json: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(json.utf8).write(to: settingsFile)
    }

    func fileJSON() throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: Data(contentsOf: settingsFile)) as! [String: Any]
    }

    @Test func firstLaunchWritesGooglePreset() throws {
        let store = SettingsStore(directory: directory)

        let json = try fileJSON()
        #expect(json["schemaVersion"] as? Int == 1)
        let general = json["general"] as! [String: Any]
        #expect(general["panelEdge"] as? String == "right")
        #expect(general["hideOnFocusLoss"] as? Bool == true)
        #expect(general["openAtLogin"] as? Bool == false)
        let depth = general["panelDepth"] as! [String: Any]
        #expect(depth["horizontal"] as? Double == 0.45)
        #expect(depth["vertical"] as? Double == 0.70)

        let profiles = json["profiles"] as! [[String: Any]]
        #expect(profiles.count == 1)
        #expect(profiles[0]["name"] as? String == "Default")
        #expect(profiles[0]["color"] as? String == "#007AFF")
        let profileId = try #require(profiles[0]["id"] as? String)
        #expect(UUID(uuidString: profileId) != nil)

        let slots = json["slots"] as! [[String: Any]]
        #expect(slots.map { $0["url"] as? String } == [
            "https://mail.google.com/", "https://calendar.google.com/", "https://chat.google.com/",
        ])
        #expect(slots.map { $0["keepAlive"] as? Bool } == [true, false, true])
        #expect(slots.map { $0["notifications"] as? Bool } == [true, true, true])
        #expect(slots.allSatisfy { $0["label"] is NSNull })
        #expect(slots.allSatisfy { $0["profileId"] as? String == profileId })
        #expect(Set(slots.compactMap { $0["id"] as? String }).count == 3)

        #expect(store.settings.slots.map(\.url.absoluteString) == [
            "https://mail.google.com/", "https://calendar.google.com/", "https://chat.google.com/",
        ])
    }

    @Test func fileIsPrettyPrintedWithSortedKeys() throws {
        _ = SettingsStore(directory: directory)

        let text = try String(contentsOf: settingsFile, encoding: .utf8)
        #expect(text.hasPrefix("{\n  \"general\" : {\n    \"hideOnFocusLoss\" : true,\n    \"openAtLogin\" : false,"))
        #expect(text.contains("\"url\" : \"https://mail.google.com/\""))
    }

    nonisolated static let validJSON = """
    {
      "schemaVersion": 1,
      "extra": "ignored",
      "general": { "panelEdge": "top", "hideOnFocusLoss": false, "openAtLogin": true,
                   "panelDepth": { "horizontal": 0.3, "vertical": 0.5 } },
      "profiles": [ { "id": "6F1C0000-0000-0000-0000-000000000001", "name": "Work", "color": "#123456" } ],
      "slots": [
        { "id": "A1000000-0000-0000-0000-000000000001", "url": "https://example.com/app", "label": "Example - Work",
          "profileId": "6F1C0000-0000-0000-0000-000000000001", "keepAlive": false, "notifications": false },
        { "id": "B2000000-0000-0000-0000-000000000002", "url": "https://mail.google.com/", "label": null,
          "profileId": "6F1C0000-0000-0000-0000-000000000001", "keepAlive": true, "notifications": true }
      ]
    }
    """

    @Test func existingFileIsLoaded() throws {
        try writeFile(Self.validJSON)

        let store = SettingsStore(directory: directory)

        let work = UUID(uuidString: "6F1C0000-0000-0000-0000-000000000001")!
        #expect(store.settings == Settings(
            schemaVersion: 1,
            general: General(panelEdge: .top, hideOnFocusLoss: false, openAtLogin: true,
                             panelDepth: .init(horizontal: 0.3, vertical: 0.5)),
            profiles: [Profile(id: work, name: "Work", color: "#123456")],
            slots: [
                Slot(id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
                     url: URL(string: "https://example.com/app")!, profileId: work,
                     label: "Example - Work", keepAlive: false, notifications: false),
                Slot(id: UUID(uuidString: "B2000000-0000-0000-0000-000000000002")!,
                     url: URL(string: "https://mail.google.com/")!, profileId: work,
                     label: nil, keepAlive: true, notifications: true),
            ]
        ))
        #expect(try String(contentsOf: settingsFile, encoding: .utf8) == Self.validJSON)
    }

    nonisolated static let corruptTime: Date = {
        var c = DateComponents()
        (c.year, c.month, c.day, c.hour, c.minute, c.second) = (2026, 3, 4, 5, 6, 7)
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    @Test(arguments: [
        "{ not json",
        Self.validJSON.replacingOccurrences(of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 2"),
        Self.validJSON.replacingOccurrences(of: "\"name\": \"Work\", ", with: ""),
        Self.validJSON.replacingOccurrences(of: "\"keepAlive\": false", with: "\"keepAlive\": \"no\""),
        Self.validJSON.replacingOccurrences(of: "\"panelEdge\": \"top\"", with: "\"panelEdge\": \"middle\""),
    ])
    func unreadableFileIsSetAsideAndPresetIsUsed(contents: String) throws {
        try writeFile(contents)

        let store = SettingsStore(directory: directory, now: { Self.corruptTime })

        let setAside = directory.appendingPathComponent("settings.corrupt-20260304-050607.json")
        #expect(try String(contentsOf: setAside, encoding: .utf8) == contents)
        #expect(store.settings.profiles.map(\.name) == ["Default"])
        let json = try fileJSON()
        #expect((json["profiles"] as? [[String: Any]])?.first?["name"] as? String == "Default")
    }

    @Test func slotsOfMissingProfilesAreDroppedAndFileRewritten() throws {
        var json = Self.validJSON
        let mailSlot = json.range(of: "B2000000-0000-0000-0000-000000000002")!
        let mailProfile = json.range(of: "6F1C0000-0000-0000-0000-000000000001", range: mailSlot.upperBound..<json.endIndex)!
        json.replaceSubrange(mailProfile, with: "DEAD0000-0000-0000-0000-000000000000")
        try writeFile(json)

        let store = SettingsStore(directory: directory)

        #expect(store.settings.slots.map(\.url.absoluteString) == ["https://example.com/app"])
        let slots = try fileJSON()["slots"] as? [[String: Any]]
        #expect(slots?.map { $0["url"] as? String } == ["https://example.com/app"])
    }

    @Test func updatesArePersistedAndPublishedToObservers() throws {
        let store = SettingsStore(directory: directory)
        var published: [General.PanelEdge] = []
        store.observe { published.append($0.general.panelEdge) }

        store.update { $0.general.panelEdge = .bottom }

        #expect(published == [.bottom])
        #expect((try fileJSON()["general"] as? [String: Any])?["panelEdge"] as? String == "bottom")
        #expect(SettingsStore(directory: directory).settings.general.panelEdge == .bottom)
    }

    @Test func togglingNotificationsPersistsImmediatelyForThatSlotOnly() {
        let store = SettingsStore(directory: directory)
        let calendar = store.settings.slots[1].id

        store.update { $0.toggleNotifications(slot: calendar) }

        let reloaded = SettingsStore(directory: directory)
        #expect(reloaded.settings.slots.map(\.notifications) == [true, false, true])
    }
}
