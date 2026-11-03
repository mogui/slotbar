import AppKit
import Testing
@testable import Slotbar

@Suite struct PanelShortcutTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let characters: String
        let modifiers: NSEvent.ModifierFlags
        let expected: PanelShortcut?
        var testDescription: String { "\(characters) \(modifiers.rawValue)" }
    }

    static let bound: [Case] = [
        Case(characters: "1", modifiers: .command, expected: .activateSlot(1)),
        Case(characters: "5", modifiers: .command, expected: .activateSlot(5)),
        Case(characters: "9", modifiers: .command, expected: .activateSlot(9)),
        Case(characters: "h", modifiers: [.command, .shift], expected: .goHome),
        Case(characters: "H", modifiers: [.command, .shift], expected: .goHome),
        Case(characters: "o", modifiers: [.command, .shift], expected: .openInBrowser),
        Case(characters: "O", modifiers: [.command, .shift], expected: .openInBrowser),
        Case(characters: "r", modifiers: .command, expected: .reload),
        Case(characters: "w", modifiers: .command, expected: .hidePanel),
    ]

    @Test(arguments: bound)
    func panelShortcutsAreRecognized(_ c: Case) {
        #expect(PanelShortcut.match(charactersIgnoringModifiers: c.characters, modifierFlags: c.modifiers) == c.expected)
    }

    @Test func modifiersOutsideCommandShiftOptionControlAreIgnored() {
        #expect(PanelShortcut.match(charactersIgnoringModifiers: "2", modifierFlags: [.command, .numericPad, .capsLock])
            == .activateSlot(2))
    }

    static let unbound: [Case] = [
        Case(characters: "\u{1b}", modifiers: [], expected: nil),
        Case(characters: "j", modifiers: [], expected: nil),
        Case(characters: "1", modifiers: [], expected: nil),
        Case(characters: "0", modifiers: .command, expected: nil),
        Case(characters: "1", modifiers: [.command, .option], expected: nil),
        Case(characters: "1", modifiers: [.command, .shift], expected: nil),
        Case(characters: "1", modifiers: [.command, .control], expected: nil),
        Case(characters: "r", modifiers: [.command, .shift], expected: nil),
        Case(characters: "h", modifiers: .command, expected: nil),
        Case(characters: "o", modifiers: .command, expected: nil),
        Case(characters: "w", modifiers: [.command, .option], expected: nil),
        Case(characters: "a", modifiers: .command, expected: nil),
    ]

    @Test(arguments: unbound)
    func otherKeysReachThePage(_ c: Case) {
        #expect(PanelShortcut.match(charactersIgnoringModifiers: c.characters, modifierFlags: c.modifiers) == nil)
    }
}
