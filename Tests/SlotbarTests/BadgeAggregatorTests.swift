import Foundation
import Testing
@testable import Slotbar

@Suite struct BadgeAggregatorTests {
    static let work = UUID()
    static let home = UUID()

    @Test func slotsOfTheSameProfileAndHomeHostCountOnceByMax() {
        let badge = BadgeAggregator.aggregate([
            SlotUnread(profileId: Self.work, homeHost: "mail.google.com", state: .count(3)),
            SlotUnread(profileId: Self.work, homeHost: "mail.google.com", state: .count(5)),
        ])
        #expect(badge == Badge(count: 5, dot: false))
    }

    @Test func groupsOfDifferentProfilesOrHomeHostsAreSummed() {
        let badge = BadgeAggregator.aggregate([
            SlotUnread(profileId: Self.work, homeHost: "mail.google.com", state: .count(3)),
            SlotUnread(profileId: Self.home, homeHost: "mail.google.com", state: .count(2)),
            SlotUnread(profileId: Self.work, homeHost: "chat.google.com", state: .count(1)),
        ])
        #expect(badge == Badge(count: 6, dot: false))
    }

    @Test func anyCountUnknownSlotAddsTheDot() {
        let badge = BadgeAggregator.aggregate([
            SlotUnread(profileId: Self.work, homeHost: "mail.google.com", state: .count(4)),
            SlotUnread(profileId: Self.work, homeHost: "chat.google.com", state: .unknown),
        ])
        #expect(badge == Badge(count: 4, dot: true))
    }

    @Test func noUnreadAnywhereIsAnEmptyBadge() {
        let badge = BadgeAggregator.aggregate([
            SlotUnread(profileId: Self.work, homeHost: "calendar.google.com", state: .none),
        ])
        #expect(badge == Badge(count: 0, dot: false))
    }
}
