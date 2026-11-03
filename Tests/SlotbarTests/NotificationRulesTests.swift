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
