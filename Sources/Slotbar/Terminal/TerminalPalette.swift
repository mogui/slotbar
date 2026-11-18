/// A Terminal theme's colors as 0xRRGGBB (Terminal spec, Appearance).
struct TerminalPalette: Equatable, Sendable {
    /// The 16 ANSI colors: 8 normal, then 8 bright.
    let ansi: [UInt32]
    let foreground: UInt32
    let background: UInt32
    let cursor: UInt32
    let selection: UInt32
}

/// The palette for a theme; `system` picks its light or dark palette from the effective appearance.
func terminalPalette(theme: TerminalSettings.Theme, dark: Bool) -> TerminalPalette {
    switch theme {
    case .system: dark ? .systemDark : .systemLight
    case .solarizedLight: .solarizedLight
    case .solarizedDark: .solarizedDark
    case .dracula: .dracula
    case .nord: .nord
    }
}

private let xterm: [UInt32] = [
    0x000000, 0xcd0000, 0x00cd00, 0xcdcd00, 0x0000ee, 0xcd00cd, 0x00cdcd, 0xe5e5e5,
    0x7f7f7f, 0xff0000, 0x00ff00, 0xffff00, 0x5c5cff, 0xff00ff, 0x00ffff, 0xffffff,
]

private let solarized: [UInt32] = [
    0x073642, 0xdc322f, 0x859900, 0xb58900, 0x268bd2, 0xd33682, 0x2aa198, 0xeee8d5,
    0x002b36, 0xcb4b16, 0x586e75, 0x657b83, 0x839496, 0x6c71c4, 0x93a1a1, 0xfdf6e3,
]

private extension TerminalPalette {
    static let systemLight = TerminalPalette(ansi: xterm, foreground: 0x000000, background: 0xffffff,
                                             cursor: 0x000000, selection: 0xb4d5fe)
    static let systemDark = TerminalPalette(ansi: xterm, foreground: 0xd4d4d4, background: 0x1e1e1e,
                                            cursor: 0xd4d4d4, selection: 0x264f78)
    static let solarizedLight = TerminalPalette(ansi: solarized, foreground: 0x657b83, background: 0xfdf6e3,
                                                cursor: 0x586e75, selection: 0xeee8d5)
    static let solarizedDark = TerminalPalette(ansi: solarized, foreground: 0x839496, background: 0x002b36,
                                               cursor: 0x93a1a1, selection: 0x073642)
    static let dracula = TerminalPalette(ansi: [
        0x21222c, 0xff5555, 0x50fa7b, 0xf1fa8c, 0xbd93f9, 0xff79c6, 0x8be9fd, 0xf8f8f2,
        0x6272a4, 0xff6e6e, 0x69ff94, 0xffffa5, 0xd6acff, 0xff92df, 0xa4ffff, 0xffffff,
    ], foreground: 0xf8f8f2, background: 0x282a36, cursor: 0xf8f8f2, selection: 0x44475a)
    static let nord = TerminalPalette(ansi: [
        0x3b4252, 0xbf616a, 0xa3be8c, 0xebcb8b, 0x81a1c1, 0xb48ead, 0x88c0d0, 0xe5e9f0,
        0x4c566a, 0xbf616a, 0xa3be8c, 0xebcb8b, 0x81a1c1, 0xb48ead, 0x8fbcbb, 0xeceff4,
    ], foreground: 0xd8dee9, background: 0x2e3440, cursor: 0xd8dee9, selection: 0x434c5e)
}
