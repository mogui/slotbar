import AppKit
import Testing
@testable import Slotbar

@Suite struct PanelShortcutTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let characters: String
        let modifiers: NSEvent.ModifierFlags
        var keyCode: UInt16 = 0
        let expected: PanelShortcut?
        var testDescription: String { "\(characters) \(modifiers.rawValue) \(keyCode)" }
    }

    func match(_ c: Case, terminalActive: Bool) -> PanelShortcut? {
        PanelShortcut.match(charactersIgnoringModifiers: c.characters, modifierFlags: c.modifiers, keyCode: c.keyCode,
                            terminalActive: terminalActive)
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
        #expect(match(c, terminalActive: false) == c.expected)
    }

    @Test func modifiersOutsideCommandShiftOptionControlAreIgnored() {
        #expect(match(Case(characters: "2", modifiers: [.command, .numericPad, .capsLock], expected: nil),
                      terminalActive: false) == .activateSlot(2))
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
        Case(characters: "t", modifiers: .command, expected: nil),
        Case(characters: "k", modifiers: .command, expected: nil),
        Case(characters: "=", modifiers: .command, expected: nil),
        Case(characters: "-", modifiers: .command, expected: nil),
        Case(characters: "{", modifiers: [.command, .shift], keyCode: 33, expected: nil),
        Case(characters: "}", modifiers: [.command, .shift], keyCode: 30, expected: nil),
    ]

    @Test(arguments: unbound)
    func otherKeysReachThePage(_ c: Case) {
        #expect(match(c, terminalActive: false) == nil)
    }

    static let terminalBound: [Case] = [
        Case(characters: "t", modifiers: .command, expected: .newTab),
        Case(characters: "w", modifiers: .command, expected: .closeTab),
        Case(characters: "{", modifiers: [.command, .shift], keyCode: 33, expected: .previousTab),
        Case(characters: "[", modifiers: [.command, .shift], keyCode: 33, expected: .previousTab),
        Case(characters: "}", modifiers: [.command, .shift], keyCode: 30, expected: .nextTab),
        Case(characters: "]", modifiers: [.command, .shift], keyCode: 30, expected: .nextTab),
        // Italian layout: the US bracket keys type "é" and "*" with Shift; matched by key code.
        Case(characters: "é", modifiers: [.command, .shift], keyCode: 33, expected: .previousTab),
        Case(characters: "*", modifiers: [.command, .shift], keyCode: 30, expected: .nextTab),
        Case(characters: "k", modifiers: .command, expected: .clear),
        Case(characters: "=", modifiers: .command, expected: .fontLarger),
        Case(characters: "+", modifiers: .command, expected: .fontLarger),
        Case(characters: "+", modifiers: [.command, .shift], expected: .fontLarger),
        Case(characters: "-", modifiers: .command, expected: .fontSmaller),
        Case(characters: "0", modifiers: .command, expected: .fontReset),
        Case(characters: "r", modifiers: .command, expected: .consume),
        Case(characters: "1", modifiers: .command, expected: .activateSlot(1)),
        Case(characters: "9", modifiers: .command, expected: .activateSlot(9)),
        Case(characters: "H", modifiers: [.command, .shift], expected: .goHome),
        Case(characters: "O", modifiers: [.command, .shift], expected: .openInBrowser),
    ]

    @Test(arguments: terminalBound)
    func terminalShortcutsAreRecognized(_ c: Case) {
        #expect(match(c, terminalActive: true) == c.expected)
    }

    static let terminalUnbound: [Case] = [
        Case(characters: "c", modifiers: .command, expected: nil),
        Case(characters: "v", modifiers: .command, expected: nil),
        Case(characters: "a", modifiers: .command, expected: nil),
        Case(characters: "t", modifiers: [.command, .shift], expected: nil),
        Case(characters: "[", modifiers: .command, keyCode: 33, expected: nil),
        Case(characters: "è", modifiers: .command, keyCode: 33, expected: nil),
        Case(characters: "w", modifiers: [.command, .option], expected: nil),
        Case(characters: "k", modifiers: [.command, .control], expected: nil),
        Case(characters: "t", modifiers: [], expected: nil),
    ]

    @Test(arguments: terminalUnbound)
    func otherKeysReachTheShell(_ c: Case) {
        #expect(match(c, terminalActive: true) == nil)
    }
}
