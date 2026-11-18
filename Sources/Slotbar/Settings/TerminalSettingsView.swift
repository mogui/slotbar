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
                Picker("Theme", selection: Binding(
                    get: { store.settings.terminal.theme },
                    set: { value in store.update { $0.terminal.theme = value } }
                )) {
                    Text("Follow system").tag(TerminalSettings.Theme.system)
                    Text("Solarized Light").tag(TerminalSettings.Theme.solarizedLight)
                    Text("Solarized Dark").tag(TerminalSettings.Theme.solarizedDark)
                    Text("Dracula").tag(TerminalSettings.Theme.dracula)
                    Text("Nord").tag(TerminalSettings.Theme.nord)
                }
                Stepper("Font size: \(Int(store.settings.terminal.fontSize)) pt", value: Binding(
                    get: { store.settings.terminal.fontSize },
                    set: { value in store.update { $0.terminal.fontSize = value } }
                ), in: TerminalSettings.fontSizeRange, step: 1)
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
