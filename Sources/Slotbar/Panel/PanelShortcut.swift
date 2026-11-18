import AppKit

/// Key equivalents the Panel consumes before the webview or the shell (SPEC 9, Terminal spec Keyboard).
enum PanelShortcut: Equatable, Sendable {
    case activateSlot(Int)
    case goHome
    case openInBrowser
    case reload
    case hidePanel
    case newTab
    case closeTab
    case previousTab
    case nextTab
    case clear
    case fontLarger
    case fontSmaller
    case fontReset
    /// Taken from the shell with no action (`Cmd+R` on the Terminal).
    case consume

    /// Matches on `charactersIgnoringModifiers` (letters case-insensitive: Shift yields "H"/"O"); the tab
    /// keys also match the US bracket key codes, which type other characters on e.g. the Italian layout.
    static func match(charactersIgnoringModifiers characters: String, modifierFlags: NSEvent.ModifierFlags,
                      keyCode: UInt16, terminalActive: Bool) -> PanelShortcut? {
        let modifiers = modifierFlags.intersection([.command, .shift, .option, .control])
        let key = characters.lowercased()
        if terminalActive {
            switch (key, modifiers) {
            case ("t", .command): return .newTab
            case ("w", .command): return .closeTab
            case ("k", .command): return .clear
            case ("=", .command), ("+", .command), ("+", [.command, .shift]): return .fontLarger
            case ("-", .command): return .fontSmaller
            case ("0", .command): return .fontReset
            case ("r", .command): return .consume
            case (_, [.command, .shift]):
                if key == "[" || key == "{" || keyCode == 33 { return .previousTab } // kVK_ANSI_LeftBracket
                if key == "]" || key == "}" || keyCode == 30 { return .nextTab } // kVK_ANSI_RightBracket
            default: break
            }
        }
        switch (key, modifiers) {
        case ("r", .command): return .reload
        case ("w", .command): return .hidePanel
        case ("h", [.command, .shift]): return .goHome
        case ("o", [.command, .shift]): return .openInBrowser
        case (let key, .command):
            guard let number = Int(key), (1...9).contains(number) else { return nil }
            return .activateSlot(number)
        default: return nil
        }
    }
}
