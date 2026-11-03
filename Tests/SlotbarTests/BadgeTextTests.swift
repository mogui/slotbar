import Testing
@testable import Slotbar

@Suite struct BadgeTextTests {
    @Test(arguments: [
        (Badge(count: 0, dot: false), nil),
        (Badge(count: 1, dot: false), "1"),
        (Badge(count: 99, dot: false), "99"),
        (Badge(count: 100, dot: false), "99+"),
        (Badge(count: 0, dot: true), "\u{25CF}"),
        (Badge(count: 7, dot: true), "7\u{25CF}"),
        (Badge(count: 250, dot: true), "99+\u{25CF}"),
    ] as [(Badge, String?)])
    func rendersCountCapAndDot(badge: Badge, text: String?) {
        #expect(badgeText(badge) == text)
    }
}
