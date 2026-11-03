import AppKit
import SwiftUI

/// Settings (SPEC 10), shown inside the Panel's Slot area: one scrolling page of grouped sections.
@MainActor
final class SettingsPane {
    private let hosting: NSHostingController<SettingsView>

    init(store: SettingsStore, hotkey: Hotkey?, openAtLogin: OpenAtLogin, favicons: FaviconCache,
         deleteProfile: @escaping (UUID) -> Void) {
        hosting = NSHostingController(rootView: SettingsView(
            store: store, hotkey: hotkey, openAtLogin: openAtLogin, favicons: favicons, deleteProfile: deleteProfile))
        hosting.sizingOptions = []
    }

    var view: NSView { hosting.view }
}

/// General, Profiles and Slots in a centered column of at most 640 pt.
struct SettingsView: View {
    let store: SettingsStore
    let hotkey: Hotkey?
    let openAtLogin: OpenAtLogin
    let favicons: FaviconCache
    let deleteProfile: (UUID) -> Void

    var body: some View {
        Form {
            GeneralView(store: store, hotkey: hotkey, openAtLogin: openAtLogin)
            ProfilesView(store: store, deleteProfile: deleteProfile)
            SlotsView(store: store, favicons: favicons)
        }
        .formStyle(.grouped)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }
}
