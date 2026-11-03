import Testing
@testable import Slotbar

@Suite struct CrashPlaceholderUnreadTests {
    @Test func countBecomesCountUnknown() {
        #expect(crashPlaceholderUnread(last: .count(4)) == .unknown)
    }

    @Test func countUnknownStaysCountUnknown() {
        #expect(crashPlaceholderUnread(last: .unknown) == .unknown)
    }

    @Test func nothingUnreadStaysNothing() {
        #expect(crashPlaceholderUnread(last: .none) == .none)
    }
}
