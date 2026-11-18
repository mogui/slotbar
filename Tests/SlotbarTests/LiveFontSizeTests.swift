import Testing
@testable import Slotbar

@Suite struct LiveFontSizeTests {
    @Test func largerAndSmallerStepOnePoint() {
        #expect(liveFontSize(15, .larger, settingsSize: 13) == 16)
        #expect(liveFontSize(15, .smaller, settingsSize: 13) == 14)
    }

    @Test func resetGoesBackToTheSettingsSize() {
        #expect(liveFontSize(20, .reset, settingsSize: 13) == 13)
    }

    @Test func staysWithinNineToThirtySix() {
        #expect(liveFontSize(36, .larger, settingsSize: 13) == 36)
        #expect(liveFontSize(9, .smaller, settingsSize: 13) == 9)
    }
}
