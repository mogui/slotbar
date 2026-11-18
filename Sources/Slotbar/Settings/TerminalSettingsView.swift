import SwiftUI

/// Settings, Terminal section (Terminal spec, Settings UI). The toggle writes immediately; turning it off
/// terminates the shells.
struct TerminalSettingsView: View {
    let store: SettingsStore

    var body: some View {
        Section("Terminal") {
            Toggle("Enable Terminal", isOn: Binding(
                get: { store.settings.terminal.enabled },
                set: { value in store.update { $0.terminal.enabled = value } }
            ))
        }
    }
}
