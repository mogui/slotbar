import AppKit

/// Non-activating Panel that floats over full-screen apps on all Spaces (SPEC 4.1).
final class PanelWindow: NSPanel {
    static let collectionBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

    init() {
        super.init(contentRect: .zero, styleMask: [.nonactivatingPanel], backing: .buffered, defer: true)
        collectionBehavior = Self.collectionBehavior
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
