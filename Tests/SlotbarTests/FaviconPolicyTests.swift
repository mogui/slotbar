import Foundation
import Testing
@testable import Slotbar

@Suite struct FaviconPolicyTests {
    static let mail = URL(string: "https://mail.google.com/mail/u/0/")!
    static let chat = URL(string: "https://chat.google.com/")!
    static let iconA = URL(string: "https://ssl.gstatic.com/a.png")!
    static let iconB = URL(string: "https://ssl.gstatic.com/b.png")!

    @Test func reportedIconLinkIsUsed() {
        #expect(faviconURL(reported: Self.iconA, slotURL: Self.mail) == Self.iconA)
    }

    @Test func missingIconLinkFallsBackToFaviconIcoOnHomeHost() {
        #expect(faviconURL(reported: nil, slotURL: Self.mail)
                == URL(string: "https://mail.google.com/favicon.ico"))
    }

    @Test func firstIconIsFetched() {
        #expect(shouldFetchFavicon(slotURL: Self.mail, lastIconURL: nil, iconURL: Self.iconA, hasCachedIcon: false))
    }

    @Test func unchangedIconLinkIsNotRefetched() {
        #expect(!shouldFetchFavicon(slotURL: Self.mail, lastIconURL: Self.iconA, iconURL: Self.iconA, hasCachedIcon: true))
    }

    @Test func changedIconLinkRefreshesTheIcon() {
        #expect(shouldFetchFavicon(slotURL: Self.mail, lastIconURL: Self.iconA, iconURL: Self.iconB, hasCachedIcon: true))
    }

    @Test func cachedIconIsReusedAfterRelaunchUntilTheLinkIsSeen() {
        // After relaunch the last link is unknown: refetch to keep the cache fresh.
        #expect(shouldFetchFavicon(slotURL: Self.mail, lastIconURL: nil, iconURL: Self.iconA, hasCachedIcon: true))
    }

    @Test func chatSlotKeepsItsFirstCachedIcon() {
        #expect(!shouldFetchFavicon(slotURL: Self.chat, lastIconURL: Self.iconA, iconURL: Self.iconB, hasCachedIcon: true))
        #expect(!shouldFetchFavicon(slotURL: Self.chat, lastIconURL: nil, iconURL: Self.iconB, hasCachedIcon: true))
    }

    @Test func chatSlotWithoutCacheFetchesItsFirstIcon() {
        #expect(shouldFetchFavicon(slotURL: Self.chat, lastIconURL: nil, iconURL: Self.iconA, hasCachedIcon: false))
    }
}

@Suite struct FaviconCachesToDeleteTests {
    static let profileA = UUID()
    static let profileB = UUID()

    static func slot(_ url: String, _ profile: UUID = profileA, label: String? = nil) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile, label: label, keepAlive: true, notifications: true)
    }

    @Test func deletedSlotLosesItsCache() {
        let mail = Self.slot("https://mail.google.com/")
        let chat = Self.slot("https://chat.google.com/")
        #expect(faviconCachesToDelete(old: [mail, chat], new: [chat]) == [mail.id])
    }

    @Test func urlOrProfileChangeDropsTheCache() {
        let mail = Self.slot("https://mail.google.com/")
        let chat = Self.slot("https://chat.google.com/")
        var movedMail = mail
        movedMail.url = URL(string: "https://mail.google.com/mail/u/1/")!
        var movedChat = chat
        movedChat.profileId = Self.profileB
        #expect(faviconCachesToDelete(old: [mail, chat], new: [movedMail, movedChat]) == [mail.id, chat.id])
    }

    @Test func otherEditsAndReorderKeepTheCache() {
        let mail = Self.slot("https://mail.google.com/")
        let chat = Self.slot("https://chat.google.com/")
        var labelled = mail
        labelled.label = "Gmail - Default"
        labelled.keepAlive = false
        labelled.notifications = false
        #expect(faviconCachesToDelete(old: [mail, chat], new: [chat, labelled]).isEmpty)
    }
}
