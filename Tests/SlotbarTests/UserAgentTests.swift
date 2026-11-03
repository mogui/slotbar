import Testing
@testable import Slotbar

@Suite struct UserAgentTests {
    static let firefox = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:157.0) Gecko/20100101 Firefox/157.0"

    @Test func missingOverrideUsesFirefoxConstant() {
        #expect(UserAgent.resolve(override: nil) == Self.firefox)
    }

    @Test(arguments: ["", "   "]) func blankOverrideUsesFirefoxConstant(blank: String) {
        #expect(UserAgent.resolve(override: blank) == Self.firefox)
    }

    @Test func overrideIsUsedVerbatim() {
        #expect(UserAgent.resolve(override: "Custom UA/1.0") == "Custom UA/1.0")
    }
}
