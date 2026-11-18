import Testing
@testable import Slotbar

@Suite struct TerminalPaletteTests {
    typealias Theme = TerminalSettings.Theme

    @Test(arguments: [(Theme.solarizedDark, 0x002b36), (.solarizedLight, 0xfdf6e3), (.dracula, 0x282a36), (.nord, 0x2e3440)])
    func namedThemesUseTheirUpstreamBackground(theme: Theme, background: Int) {
        #expect(terminalPalette(theme: theme, dark: false).background == UInt32(background))
        #expect(terminalPalette(theme: theme, dark: true).background == UInt32(background))
    }

    @Test func draculaAndNordUseTheirUpstreamForeground() {
        #expect(terminalPalette(theme: .dracula, dark: false).foreground == 0xf8f8f2)
        #expect(terminalPalette(theme: .nord, dark: false).foreground == 0xd8dee9)
    }

    @Test func followSystemIsLightOrDarkWithTheAppearance() {
        let light = terminalPalette(theme: .system, dark: false)
        let dark = terminalPalette(theme: .system, dark: true)
        #expect(light.background == 0xffffff)
        #expect(light.foreground == 0x000000)
        #expect(dark.background == 0x1e1e1e)
        #expect(dark.foreground == 0xd4d4d4)
    }

    @Test(arguments: [Theme.system, .solarizedLight, .solarizedDark, .dracula, .nord], [false, true])
    func everyPaletteHasTheSixteenAnsiColors(theme: Theme, dark: Bool) {
        #expect(terminalPalette(theme: theme, dark: dark).ansi.count == 16)
    }
}
