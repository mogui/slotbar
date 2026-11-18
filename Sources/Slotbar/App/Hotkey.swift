import AppKit
import Carbon.HIToolbox
import KeyboardShortcuts
import Observation

private let log = Log.logger("App")

extension KeyboardShortcuts.Name {
    /// Global Panel toggle, default `Ctrl+Option+S` (SPEC 9).
    nonisolated(unsafe) static let togglePanel = Self("togglePanel", default: .init(.s, modifiers: [.control, .option]))
    /// Terminal hotkey, default `Ctrl+Option+T`; registered only while the Terminal is on (Terminal spec).
    nonisolated(unsafe) static let toggleTerminal = Self("toggleTerminal", default: .init(.t, modifiers: [.control, .option]))
}

/// Registers the global hotkey and tracks whether its registration failed (SPEC 9).
/// `isUnavailable` drives both the status menu line and the Settings inline warning.
@MainActor
@Observable
final class Hotkey {
    private(set) var isUnavailable = false

    init(onKeyDown: @escaping @MainActor () -> Void, onTerminalKeyDown: @escaping @MainActor () -> Void) {
        // KeyboardShortcuts ignores RegisterEventHotKey failures, so probe before it registers.
        isUnavailable = !Self.canRegister(KeyboardShortcuts.getShortcut(for: .togglePanel))
        KeyboardShortcuts.onKeyDown(for: .togglePanel) { MainActor.assumeIsolated { onKeyDown() } }
        KeyboardShortcuts.onKeyDown(for: .toggleTerminal) { MainActor.assumeIsolated { onTerminalKeyDown() } }
        NotificationCenter.default.addObserver(
            forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reprobe() }
        }
        if isUnavailable { log.error("Global hotkey registration failed") }
    }

    /// Registers the Terminal hotkey while the Terminal is on; off, the key combination stays free for other apps.
    func setTerminalEnabled(_ enabled: Bool) {
        if enabled { KeyboardShortcuts.enable(.toggleTerminal) } else { KeyboardShortcuts.disable(.toggleTerminal) }
    }

    /// Re-probes after a recorder change, with KeyboardShortcuts' own registration lifted so it does not collide.
    private func reprobe() {
        KeyboardShortcuts.disable(.togglePanel)
        isUnavailable = !Self.canRegister(KeyboardShortcuts.getShortcut(for: .togglePanel))
        KeyboardShortcuts.enable(.togglePanel)
        if isUnavailable { log.error("Global hotkey registration failed") }
    }

    /// A cleared shortcut counts as available: there is nothing to register.
    private static func canRegister(_ shortcut: KeyboardShortcuts.Shortcut?) -> Bool {
        guard let shortcut else { return true }
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.carbonKeyCode), UInt32(shortcut.carbonModifiers),
            EventHotKeyID(signature: OSType(0x534C_4252), id: 1), // 'SLBR'
            GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        UnregisterEventHotKey(ref)
        return true
    }
}
