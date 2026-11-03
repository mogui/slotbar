import Foundation
import Testing
@testable import Slotbar

@Suite struct ReopenURLTests {
    let mail = Slot(id: UUID(), url: URL(string: "https://mail.google.com/mail/u/0/")!, profileId: UUID(),
                    label: nil, keepAlive: false, notifications: true)

    @Test func homeHostPageReopensWhereItWas() {
        let last = URL(string: "https://mail.google.com/mail/u/0/#inbox/FMfcg123")!
        #expect(reopenURL(lastURL: last, slot: mail) == last)
    }

    @Test func signInHostCountsAsForeign() {
        let last = URL(string: "https://accounts.google.com/v3/signin/identifier")!
        #expect(reopenURL(lastURL: last, slot: mail) == mail.url)
    }

    @Test func anotherHostReopensAtStartingURL() {
        #expect(reopenURL(lastURL: URL(string: "https://docs.google.com/document/d/1")!, slot: mail) == mail.url)
    }

    @Test func neverLoadedReopensAtStartingURL() {
        #expect(reopenURL(lastURL: nil, slot: mail) == mail.url)
    }
}
