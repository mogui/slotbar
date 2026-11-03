import Foundation
import Testing
@testable import Slotbar

@Suite struct SignInModeTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func activeAfterEntry() {
        var mode = SignInMode()
        mode.enter(at: start)
        #expect(mode.isActive(at: start.addingTimeInterval(9 * 60)))
    }

    @Test func inactiveUntilEntered() {
        #expect(!SignInMode().isActive(at: start))
    }

    @Test func endsTenMinutesAfterEntry() {
        var mode = SignInMode()
        mode.enter(at: start)
        #expect(!mode.isActive(at: start.addingTimeInterval(10 * 60)))
    }

    @Test func endsWhenMainFrameCommitsOnHomeHost() {
        var mode = SignInMode()
        mode.enter(at: start)
        mode.didCommit(URL(string: "https://mail.google.com/mail/u/0/")!, homeHost: "mail.google.com")
        #expect(!mode.isActive(at: start.addingTimeInterval(60)))
    }

    @Test func commitOnAnotherHostKeepsItActive() {
        var mode = SignInMode()
        mode.enter(at: start)
        mode.didCommit(URL(string: "https://accounts.google.com/signin/challenge")!, homeHost: "mail.google.com")
        #expect(mode.isActive(at: start.addingTimeInterval(60)))
    }

    @Test func reenteringWhileActiveKeepsTheFirstEntryTime() {
        var mode = SignInMode()
        mode.enter(at: start)
        mode.enter(at: start.addingTimeInterval(8 * 60))
        #expect(!mode.isActive(at: start.addingTimeInterval(10 * 60)))
    }

    @Test func reenteringAfterTimeoutStartsAFreshTenMinutes() {
        var mode = SignInMode()
        mode.enter(at: start)
        mode.enter(at: start.addingTimeInterval(11 * 60))
        #expect(mode.isActive(at: start.addingTimeInterval(20 * 60)))
    }
}
