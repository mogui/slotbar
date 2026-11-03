import SwiftUI

/// Settings, Profiles section (SPEC 10.2): color swatch, inline-editable name, delete button per row, "+" in the header.
struct ProfilesView: View {
    let store: SettingsStore
    /// Runs the deletion cascade (SPEC 3.4, 5).
    let deleteProfile: (UUID) -> Void
    @State private var pendingDeletion: Profile?

    var body: some View {
        Section {
            ForEach(store.settings.profiles) { profile in
                ProfileRow(store: store, profile: profile) { pendingDeletion = profile }
            }
            if store.settings.profiles.isEmpty {
                Text("No Profiles").foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Profiles")
                Spacer()
                Button { add() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .help("Add Profile")
            }
        }
        .alert(deletionTitle, isPresented: Binding(get: { pendingDeletion != nil },
                                                  set: { if !$0 { pendingDeletion = nil } }),
               presenting: pendingDeletion) { profile in
            Button("Delete", role: .destructive) { deleteProfile(profile.id) }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            Text(deletionMessage(profile))
        }
    }

    private var deletionTitle: String {
        "Delete \"\(pendingDeletion?.name ?? "")\"?"
    }

    private func deletionMessage(_ profile: Profile) -> String {
        let slots = store.settings.slots(inProfile: profile.id)
        let session = "Its sign-in session and site data are removed."
        guard !slots.isEmpty else { return "No Slots use this Profile. \(session)" }
        let names = slots.map { "- \($0.label ?? $0.url.host() ?? $0.url.absoluteString)" }
        return "These Slots will be deleted with it:\n\(names.joined(separator: "\n"))\n\n\(session)"
    }

    private func add() {
        store.update { $0.addProfile(id: UUID()) }
    }
}

private struct ProfileRow: View {
    let store: SettingsStore
    let profile: Profile
    let delete: () -> Void
    @State private var name = ""
    @State private var choosingColor = false
    @FocusState private var editing: Bool

    var body: some View {
        HStack {
            Button { choosingColor = true } label: { Swatch(hex: profile.color) }
                .buttonStyle(.plain)
                .popover(isPresented: $choosingColor) {
                    HStack(spacing: 8) {
                        ForEach(ProfilePalette.colors, id: \.hex) { color in
                            Button { setColor(color.hex) } label: { Swatch(hex: color.hex) }
                                .buttonStyle(.plain)
                                .help(color.name)
                        }
                    }
                    .padding(10)
                }
            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .focused($editing)
                .onSubmit(commit)
                .onChange(of: editing) { _, isEditing in if !isEditing { commit() } }
            Button(action: delete) { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Delete Profile")
        }
        .onAppear { name = profile.name }
        .onChange(of: profile.name) { _, newName in name = newName }
    }

    /// A blank name reverts to the saved one.
    private func commit() {
        store.update { $0.renameProfile(profile.id, to: name) }
        name = store.settings.profiles.first { $0.id == profile.id }?.name ?? name
    }

    private func setColor(_ hex: String) {
        store.update { settings in
            if let index = settings.profiles.firstIndex(where: { $0.id == profile.id }) {
                settings.profiles[index].color = hex
            }
        }
        choosingColor = false
    }
}

private struct Swatch: View {
    let hex: String

    var body: some View {
        Circle()
            .fill(Color(nsColor: ProfileColor(hex: hex).nsColor))
            .frame(width: 14, height: 14)
    }
}
