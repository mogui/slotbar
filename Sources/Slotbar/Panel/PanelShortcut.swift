import AppKit

/// Key equivalents the Panel consumes before the webview (SPEC 9).
enum PanelShortcut: Equatable, Sendable {
    case activateSlot(Int)
    case goHome
    case openInBrowser
    case reload
    case hidePanel

    /// Matches on `charactersIgnoringModifiers` (letters case-insensitive: Shift yields "H"/"O").
    static func match(charactersIgnoringModifiers characters: String, modifierFlags: NSEvent.ModifierFlags) -> PanelShortcut? {
        let modifiers = modifierFlags.intersection([.command, .shift, .option, .control])
        switch (characters.lowercased(), modifiers) {
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
