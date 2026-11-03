import Foundation
import Testing
@testable import Slotbar

@Suite struct NotificationRequestIdTests {
    let profile = UUID(uuidString: "5B0C9E4A-1F2D-4C3B-9A8E-7D6F5E4C3B2A")!

    @Test func taggedNotificationIdIsProfileHostAndTag() {
        let id = notificationRequestId(profileId: profile, originHost: "chat.google.com", tag: "room-42")
        #expect(id == "5B0C9E4A-1F2D-4C3B-9A8E-7D6F5E4C3B2A|chat.google.com|room-42")
    }

    @Test(arguments: [nil, ""] as [String?])
    func untaggedNotificationGetsARandomId(tag: String?) {
        let random = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let id = notificationRequestId(profileId: profile, originHost: "chat.google.com", tag: tag, random: random)
        #expect(id == "00000000-0000-0000-0000-0000000000AA")
    }
}

@Suite struct NotificationDeliveryTests {
    static let work = UUID()
    static let personal = UUID()
    static func slot(_ url: String, profile: UUID = work, notifications: Bool = true) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile, label: nil, keepAlive: true, notifications: notifications)
    }

    let mail = slot("https://mail.google.com/")
    let chat = slot("https://chat.google.com/")

    @Test func copyFromAnotherLoadedSlotsOriginIsDropped() {
        let decision = notificationDecision(slot: mail, originHost: "chat.google.com", loadedSlots: [mail, chat])
        #expect(decision == .duplicate)
    }

    @Test func otherOriginIsDeliveredWhenItsSlotIsNotLoaded() {
        #expect(notificationDecision(slot: mail, originHost: "chat.google.com", loadedSlots: [mail]) == .deliver)
    }

    @Test func otherOriginIsDeliveredWhenItsSlotIsInAnotherProfile() {
        let personalChat = Self.slot("https://chat.google.com/", profile: Self.personal)
        #expect(notificationDecision(slot: mail, originHost: "chat.google.com", loadedSlots: [mail, personalChat]) == .deliver)
    }

    @Test func ownHomeHostIsDeliveredEvenWhenAnotherSlotSharesIt() {
        let secondMail = Self.slot("https://mail.google.com/")
        #expect(notificationDecision(slot: mail, originHost: "mail.google.com", loadedSlots: [mail, secondMail]) == .deliver)
    }

    @Test func homeHostsCompareCaseInsensitively() {
        let upperChat = Self.slot("https://Chat.Google.com/")
        #expect(notificationDecision(slot: mail, originHost: "chat.google.com", loadedSlots: [mail, upperChat]) == .duplicate)
    }

    @Test func slotWithNotificationsOffDropsThem() {
        let quietChat = Self.slot("https://chat.google.com/", notifications: false)
        #expect(notificationDecision(slot: quietChat, originHost: "chat.google.com", loadedSlots: [mail, quietChat]) == .notificationsOff)
    }

    @Test func loadedSlotWithNotificationsOffStillSuppressesTheCopy() {
        let quietChat = Self.slot("https://chat.google.com/", notifications: false)
        #expect(notificationDecision(slot: mail, originHost: "chat.google.com", loadedSlots: [mail, quietChat]) == .duplicate)
    }
}

@Suite struct NotificationPresentationTests {
    let mail = UUID()
    let chat = UUID()

    @Test func suppressedWhilePanelShowsTheOriginatingSlot() {
        #expect(foregroundPresentation(originSlot: chat, panelShowing: chat, silent: false) == [])
    }

    @Test(arguments: [nil, UUID()] as [UUID?])
    func shownAsBannerWhenThePanelIsNotShowingTheOriginatingSlot(panelShowing: UUID?) {
        #expect(foregroundPresentation(originSlot: chat, panelShowing: panelShowing, silent: false) == [.banner, .list, .sound])
    }

    @Test func silentNotificationHasNoSound() {
        #expect(foregroundPresentation(originSlot: chat, panelShowing: mail, silent: true) == [.banner, .list])
    }
}

@Suite struct NotificationDeepLinkTests {
    @Test func chatSpaceMessageOpensTheSpace() {
        let data = #"["PL9xKKUtSuE/115521195953099467914",[[null,null,null,[null,"6EnDSgKhB6g",[["AAQAxPYsHog"]]]],"PL9xKKUtSuE"]]"#
        #expect(notificationDeepLink(originHost: "chat.google.com", dataJSON: data)?.absoluteString
            == "https://chat.google.com/app/chat/AAQAxPYsHog")
    }

    /// What the shim sends: Chat's `data` is itself a string, so `JSON.stringify` wraps it in quotes.
    @Test func chatDataPostedAsAJSONStringOpensTheSpace() {
        let data = #""[\"PL9xKKUtSuE/115521195953099467914\",[[null,null,null,[null,\"6EnDSgKhB6g\",[[\"AAQAxPYsHog\"]]]],\"PL9xKKUtSuE\"]]""#
        #expect(notificationDeepLink(originHost: "chat.google.com", dataJSON: data)?.absoluteString
            == "https://chat.google.com/app/chat/AAQAxPYsHog")
    }

    @Test func chatDirectMessageOpensTheDM() {
        let data = #"["__g-hcGO2b4/115521195953099467914",[[null,null,null,[null,"__g-hcGO2b4",[null,null,["_SeRSCAAAAE"]]]],"__g-hcGO2b4"]]"#
        #expect(notificationDeepLink(originHost: "chat.google.com", dataJSON: data)?.absoluteString
            == "https://chat.google.com/app/chat/_SeRSCAAAAE")
    }

    @Test(arguments: [nil, "", "null", "{}", #"["a"]"#, #"["a",[[null,null,null,[null,"t",[["../x"]]]]]]"#] as [String?])
    func unrecognizedDataHasNoLink(data: String?) {
        #expect(notificationDeepLink(originHost: "chat.google.com", dataJSON: data) == nil)
    }

    @Test func otherHostsHaveNoLink() {
        let data = #"["m",[[null,null,null,[null,"t",[["AAQAxPYsHog"]]]],"m"]]"#
        #expect(notificationDeepLink(originHost: "mail.google.com", dataJSON: data) == nil)
    }
}
