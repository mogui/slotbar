import KeyboardShortcuts
import SwiftUI

/// Settings, Terminal section (Terminal spec, Settings UI). Every edit writes immediately (text fields on Return or
/// leaving the field); turning it off terminates the shells, after one confirmation when any tab is busy. Shell and
/// directory apply to shells spawned afterwards.
struct TerminalSettingsView: View {
    let store: SettingsStore
    /// False when the user cancels the busy-tab confirmation: the Terminal stays on.
    let confirmTurnOff: () -> Bool
    /// Bumped on a cancelled turn-off: the switch already flipped itself and the store did not change.
    @State private var cancelledTurnOffs = 0

    var body: some View {
        Section("Terminal") {
            Toggle("Enable Terminal", isOn: Binding(
                get: { store.settings.terminal.enabled },
                set: { value in
                    if value || confirmTurnOff() {
                        store.update { $0.terminal.enabled = value }
                    } else {
                        cancelledTurnOffs += 1
                    }
                }
            ))
            .id(cancelledTurnOffs)
            Group {
                LabeledContent("Terminal hotkey") {
                    HotkeyRecorder(name: .toggleTerminal, other: .togglePanel, otherLabel: "Panel hotkey")
                }
                Picker("Theme", selection: Binding(
                    get: { store.settings.terminal.theme },
                    set: { value in store.update { $0.terminal.theme = value } }
                )) {
                    ForEach(TerminalSettings.Theme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Stepper("Font size: \(Int(store.settings.terminal.fontSize)) pt", value: Binding(
                    get: { store.settings.terminal.fontSize },
                    set: { value in store.update { $0.terminal.fontSize = value } }
                ), in: TerminalSettings.fontSizeRange, step: 1)
                CommittedTextField(title: "Shell", prompt: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh",
                                   store: store, keyPath: \.shellPath)
                CommittedTextField(title: "Starting directory", prompt: "~", store: store, keyPath: \.startDirectory)
            }
            .disabled(!store.settings.terminal.enabled)
        }
    }

}

/// A path field written on Return or when it loses focus, not per keystroke (each write applies all settings).
/// An empty field is null: `$SHELL` or home.
private struct CommittedTextField: View {
    let title: String
    let prompt: String
    let store: SettingsStore
    let keyPath: WritableKeyPath<TerminalSettings, String?>
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(title, text: $text, prompt: Text(prompt))
            .focused($focused)
            .onSubmit(commit)
            .onChange(of: focused) { if !focused { commit() } }
            .onDisappear(perform: commit)
            .onAppear { text = store.settings.terminal[keyPath: keyPath] ?? "" }
    }

    private func commit() {
        let value = text.isEmpty ? nil : text
        if store.settings.terminal[keyPath: keyPath] != value { store.update { $0.terminal[keyPath: keyPath] = value } }
    }
}

private extension TerminalSettings.Theme {
    var displayName: String {
        switch self {
        case .system: "Follow system"
        case .solarizedLight: "Solarized Light"
        case .solarizedDark: "Solarized Dark"
        case .dracula: "Dracula"
        case .nord: "Nord"
        }
    }
}

/// A hotkey recorder that refuses the other hotkey's shortcut: KeyboardShortcuts registers by shortcut, so a shared
/// combination fires both, and disabling one (Terminal off) unregisters the other.
struct HotkeyRecorder: View {
    let name: KeyboardShortcuts.Name
    let other: KeyboardShortcuts.Name
    let otherLabel: String
    @State private var clashed = false

    var body: some View {
        VStack(alignment: .trailing) {
            KeyboardShortcuts.Recorder(for: name) { shortcut in
                clashed = shortcut != nil && shortcut == KeyboardShortcuts.getShortcut(for: other)
                if clashed { KeyboardShortcuts.setShortcut(nil, for: name) }
            }
            if clashed {
                Label("Already used by the \(otherLabel)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }
        }
    }
}
