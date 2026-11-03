import Foundation
import Testing
@testable import Slotbar

@Suite struct ProfilePaletteTests {
    private func profiles(_ colors: [String]) -> [Profile] {
        colors.map { Profile(id: UUID(), name: "P", color: $0) }
    }

    @Test func noProfilesGetsBlue() {
        #expect(ProfilePalette.colorForNewProfile(existing: []) == "#007AFF")
    }

    @Test func firstUnusedColorInPaletteOrder() {
        #expect(ProfilePalette.colorForNewProfile(existing: profiles(["#007AFF", "#FF2D55"])) == "#AF52DE")
    }

    @Test func colorMatchIsCaseInsensitive() {
        #expect(ProfilePalette.colorForNewProfile(existing: profiles(["#007aff"])) == "#AF52DE")
    }

    @Test func allUsedPicksLeastUsed() {
        let all = ["#007AFF", "#AF52DE", "#FF2D55", "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#8E8E93"]
        let used = all + ["#007AFF", "#AF52DE", "#FF3B30"]
        #expect(ProfilePalette.colorForNewProfile(existing: profiles(used)) == "#FF2D55")
    }

    @Test func allUsedEquallyPicksFirstInPaletteOrder() {
        let all = ["#8E8E93", "#34C759", "#FFCC00", "#FF9500", "#FF3B30", "#FF2D55", "#AF52DE", "#007AFF"]
        #expect(ProfilePalette.colorForNewProfile(existing: profiles(all + all)) == "#007AFF")
    }

    @Test func offPaletteColorsDoNotCount() {
        #expect(ProfilePalette.colorForNewProfile(existing: profiles(["#123456"])) == "#007AFF")
    }
}
