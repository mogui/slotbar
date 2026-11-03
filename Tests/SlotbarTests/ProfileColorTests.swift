import Testing
@testable import Slotbar

@Suite struct ProfileColorTests {
    @Test func paletteBlueParses() {
        #expect(ProfileColor(hex: "#007AFF") == ProfileColor(red: 0, green: 122, blue: 255))
    }

    @Test func offPaletteHexIsShownAsIs() {
        #expect(ProfileColor(hex: "#12ab9C") == ProfileColor(red: 0x12, green: 0xAB, blue: 0x9C))
    }

    @Test(arguments: ["", "007AFF", "#07F", "#GG0000", "#007AFF00", "blue"])
    func invalidHexFallsBackToGraphite(hex: String) {
        #expect(ProfileColor(hex: hex) == ProfileColor(red: 0x8E, green: 0x8E, blue: 0x93))
    }
}
