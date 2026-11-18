import KeyboardShortcuts
import SwiftUI

/// Settings, Terminal section (Terminal spec, Settings UI). Every edit writes immediately; turning it off
/// terminates the shells. Shell and directory apply to shells spawned afterwards.
struct TerminalSettingsView: View {
    let store: SettingsStore

    var body: some View {
        Section("Terminal") {
            Toggle("Enable Terminal", isOn: Binding(
                get: { store.settings.terminal.enabled },
                set: { value in store.update { $0.terminal.enabled = value } }
            ))
            Group {
                LabeledContent("Terminal hotkey") {
                    KeyboardShortcuts.Recorder(for: .toggleTerminal)
                }
                TextField("Shell", text: binding(\.shellPath),
                          prompt: Text(ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"))
                TextField("Starting directory", text: binding(\.startDirectory), prompt: Text("~"))
            }
            .disabled(!store.settings.terminal.enabled)
        }
    }

    /// An empty field is null: `$SHELL` or home.
    private func binding(_ keyPath: WritableKeyPath<TerminalSettings, String?>) -> Binding<String> {
        Binding(
            get: { store.settings.terminal[keyPath: keyPath] ?? "" },
            set: { value in store.update { $0.terminal[keyPath: keyPath] = value.isEmpty ? nil : value } }
        )
    }
}
