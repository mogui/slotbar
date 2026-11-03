import AppKit

/// Non-activating Panel that floats over full-screen apps on all Spaces (SPEC 4.1).
final class PanelWindow: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.nonactivatingPanel], backing: .buffered, defer: true)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    /// Handles Panel shortcuts before the webview sees them (SPEC 9).
    var onShortcut: ((PanelShortcut) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let characters = event.charactersIgnoringModifiers, let onShortcut,
           let shortcut = PanelShortcut.match(charactersIgnoringModifiers: characters, modifierFlags: event.modifierFlags) {
            onShortcut(shortcut)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
