import Testing
@testable import Slotbar

@Suite struct TitleUnreadTests {
    @Test(arguments: [
        ("(3) Inbox - Example", UnreadState.count(3)),
        ("(120) Feed", .count(120)),
        ("(0) Feed", .none),
        ("Inbox (3)", .none),
        ("Calendar - Week of Nov 3", .none),
        ("", .none),
    ] as [(String, UnreadState)])
    func leadingParenthesizedCountIsTheUnreadState(title: String, state: UnreadState) {
        #expect(titleUnread(title) == state)
    }
}

@Suite struct ChatUnreadTests {
    static let dot = "https://www.gstatic.com/dynamite/images/favicon/chat_dot_2020q4v2_32dp.png"
    static let noDot = "https://www.gstatic.com/dynamite/images/favicon/chat_no_dot_2020q4v2_32dp.png"

    @Test func dotFaviconIsCountUnknown() {
        #expect(chatUnread(faviconHref: Self.dot, last: .none) == .unknown)
    }

    @Test func noDotFaviconIsNone() {
        #expect(chatUnread(faviconHref: Self.noDot, last: .unknown) == .none)
    }

    @Test(arguments: [nil, "https://chat.google.com/favicon.ico"] as [String?])
    func unrecognizedFaviconKeepsTheLastState(href: String?) {
        #expect(chatUnread(faviconHref: href, last: .unknown) == .unknown)
    }
}

@Suite struct GmailUnreadTests {
    @Test func domCountIsTheUnreadState() {
        var gmail = GmailUnread()
        gmail.apply(.dom(4))
        #expect(gmail.state == .count(4))
    }

    @Test func domCountOfZeroIsNone() {
        var gmail = GmailUnread()
        gmail.apply(.dom(4))
        gmail.apply(.dom(0))
        #expect(gmail.state == .none)
    }

    @Test func atomFallbackCountIsTheUnreadState() {
        var gmail = GmailUnread()
        gmail.apply(.atom(2))
        #expect(gmail.state == .count(2))
    }

    @Test(arguments: [
        (GmailSignal.dom(5), UnreadState.unknown),
        (.dom(0), .none),
        (.failed, .none),
    ] as [(GmailSignal, UnreadState)])
    func bothSourcesFailingNeverInventsACount(before: GmailSignal, state: UnreadState) {
        var gmail = GmailUnread()
        gmail.apply(before)
        gmail.apply(.failed)
        #expect(gmail.state == state)
    }

    @Test func failingAfterUnknownStaysUnknown() {
        var gmail = GmailUnread()
        gmail.apply(.dom(5))
        gmail.apply(.failed)
        gmail.apply(.failed)
        #expect(gmail.state == .unknown)
    }

    @Test func reportsASwitchOnlyWhenTheSourceChanges() {
        var gmail = GmailUnread()
        #expect(gmail.apply(.dom(1)) == .dom)
        #expect(gmail.apply(.dom(2)) == nil)
        #expect(gmail.apply(.atom(2)) == .atom)
        #expect(gmail.apply(.atom(3)) == nil)
        #expect(gmail.apply(.failed) == .failed)
        #expect(gmail.apply(.dom(3)) == .dom)
    }
}
