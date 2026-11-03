import AppKit
import KeyboardShortcuts
import SwiftUI
import UserNotifications

/// Settings > General (SPEC 10.1). Every edit writes through `SettingsStore` and applies live.
struct GeneralView: View {
    let store: SettingsStore
    let hotkey: Hotkey?
    let openAtLogin: OpenAtLogin
    @State private var notificationsDenied = false

    var body: some View {
        Form {
            LabeledContent("Global hotkey:") {
                VStack(alignment: .leading, spacing: 4) {
                    KeyboardShortcuts.Recorder(for: .togglePanel)
                    if hotkey?.isUnavailable == true {
                        Label("This shortcut could not be registered. Choose another one.",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                }
            }
            Picker("Panel edge:", selection: binding(\.panelEdge)) {
                Text("Left").tag(General.PanelEdge.left)
                Text("Right").tag(General.PanelEdge.right)
                Text("Top").tag(General.PanelEdge.top)
                Text("Bottom").tag(General.PanelEdge.bottom)
            }
            .pickerStyle(.radioGroup)
            Toggle("Hide when Slotbar loses focus", isOn: binding(\.hideOnFocusLoss))
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Open at login", isOn: Binding(
                    get: { store.settings.general.openAtLogin },
                    set: { openAtLogin.set($0) }
                ))
                if let error = openAtLogin.error {
                    Text("Open at login failed: \(error)")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            if notificationsDenied {
                HStack {
                    Text("Notifications are off in System Settings")
                    Button("Open") { openNotificationSettings() }
                }
            }
        }
        .padding(20)
        .frame(width: 460)
        .fixedSize()
        .task { await refreshNotificationStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshNotificationStatus() }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<General, Value>) -> Binding<Value> {
        Binding(
            get: { store.settings.general[keyPath: keyPath] },
            set: { value in store.update { $0.general[keyPath: keyPath] = value } }
        )
    }

    private func refreshNotificationStatus() async {
        // UNUserNotificationCenter needs an app bundle; `swift run` has none.
        guard Bundle.main.bundleIdentifier != nil else { return }
        notificationsDenied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    private func openNotificationSettings() {
        let id = Bundle.main.bundleIdentifier ?? ""
        let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)")!
        NSWorkspace.shared.open(url)
    }
}
