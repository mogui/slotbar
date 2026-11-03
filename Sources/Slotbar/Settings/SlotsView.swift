import SwiftUI

/// Settings > Slots (SPEC 10.3): Slots in list order, reordered by drag and drop, edited inline, +/- buttons.
struct SlotsView: View {
    let store: SettingsStore
    let favicons: FaviconCache
    @State private var selection: UUID?
    @State private var adding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SlotColumns(icon: Text(""), label: Text("Label"), url: Text("URL"), profile: Text("Profile"),
                        keepAlive: Text("Keep-alive"), notifications: Text("Notifications"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            List(selection: $selection) {
                ForEach(store.settings.slots) { slot in
                    SlotRow(store: store, slot: slot, icon: favicons.image(for: slot.id)).tag(slot.id)
                }
                .onMove { source, destination in
                    store.update { $0.moveSlots(fromOffsets: source, toOffset: destination) }
                }
            }
            .listStyle(.bordered)
            .frame(height: 260)
            HStack(spacing: 0) {
                Button { adding = true } label: { Image(systemName: "plus").frame(width: 24, height: 20) }
                    .disabled(store.settings.profiles.isEmpty)
                Button { delete() } label: { Image(systemName: "minus").frame(width: 24, height: 20) }
                    .disabled(selection.map { id in !store.settings.slots.contains { $0.id == id } } ?? true)
                if store.settings.profiles.isEmpty {
                    Text("Add a Profile first")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                }
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 760)
        .fixedSize()
        .sheet(isPresented: $adding) {
            AddSlotSheet(profiles: store.settings.profiles) { url, profileId in
                let id = UUID()
                store.update { $0.addSlot(id: id, url: url, profileId: profileId) }
                selection = id
            }
        }
    }

    /// No confirmation (SPEC 10.3); `AppDelegate.apply` closes the Slot, its notifications and favicon (SPEC 5).
    private func delete() {
        guard let selection else { return }
        store.update { $0.deleteSlot(selection) }
        self.selection = nil
    }
}

/// Column widths shared by the header and the rows.
private struct SlotColumns<Icon: View, LabelView: View, URLView: View, ProfileView: View, KeepAlive: View, Notifications: View>: View {
    let icon: Icon
    let label: LabelView
    let url: URLView
    let profile: ProfileView
    let keepAlive: KeepAlive
    let notifications: Notifications

    var body: some View {
        HStack(spacing: 8) {
            icon.frame(width: 18)
            label.frame(width: 170, alignment: .leading)
            url.frame(width: 230, alignment: .leading)
            profile.frame(width: 120, alignment: .leading)
            keepAlive.frame(width: 70)
            notifications.frame(width: 80)
        }
    }
}

private struct SlotRow: View {
    let store: SettingsStore
    let slot: Slot
    let icon: NSImage?
    @State private var label = ""
    @State private var url = ""
    @FocusState private var focus: Field?

    private enum Field { case label, url }

    var body: some View {
        SlotColumns(
            icon: iconView,
            label: TextField("Label", text: $label, prompt: Text(slot.url.host() ?? ""))
                .textFieldStyle(.plain)
                .focused($focus, equals: .label)
                .onSubmit(commitLabel),
            url: TextField("URL", text: $url)
                .textFieldStyle(.plain)
                .focused($focus, equals: .url)
                .onSubmit(commitURL),
            profile: Picker("Profile", selection: Binding(
                get: { slot.profileId },
                set: { id in if id != slot.profileId { store.update { $0.setProfile(slot: slot.id, to: id) } } }
            )) {
                ForEach(store.settings.profiles) { Text($0.name).tag($0.id) }
            }
            .labelsHidden(),
            keepAlive: Toggle("Keep-alive", isOn: binding(\.keepAlive)).labelsHidden(),
            notifications: Toggle("Notifications", isOn: binding(\.notifications)).labelsHidden()
        )
        .toggleStyle(.checkbox)
        .onAppear { label = slot.label ?? ""; url = slot.url.absoluteString }
        .onChange(of: slot.label) { _, new in label = new ?? "" }
        .onChange(of: slot.url) { _, new in url = new.absoluteString }
        .onChange(of: focus) { old, _ in
            if old == .label { commitLabel() }
            if old == .url { commitURL() }
        }
    }

    @ViewBuilder private var iconView: some View {
        if let icon {
            Image(nsImage: icon).resizable().frame(width: 16, height: 16)
        } else {
            Image(systemName: "globe")
                .foregroundStyle(Color(nsColor: ProfileColor(hex: profileColor).nsColor))
        }
    }

    private var profileColor: String {
        store.settings.profiles.first { $0.id == slot.profileId }?.color ?? ""
    }

    /// Clearing the label sets it to null (SPEC 10.3).
    private func commitLabel() {
        let stored = slot.label ?? ""
        guard label != stored else { return }
        store.update { $0.setLabel(slot: slot.id, to: label) }
        label = store.settings.slots.first { $0.id == slot.id }?.label ?? ""
    }

    /// Invalid input reverts to the saved URL.
    private func commitURL() {
        guard let parsed = slotURL(from: url) else {
            url = slot.url.absoluteString
            return
        }
        if parsed != slot.url { store.update { $0.setURL(slot: slot.id, to: parsed) } }
        url = parsed.absoluteString
    }

    private func binding(_ keyPath: WritableKeyPath<Slot, Bool>) -> Binding<Bool> {
        Binding(
            get: { slot[keyPath: keyPath] },
            set: { value in
                store.update { settings in
                    if let index = settings.slots.firstIndex(where: { $0.id == slot.id }) {
                        settings.slots[index][keyPath: keyPath] = value
                    }
                }
            }
        )
    }
}

/// "+" sheet: URL (required) and Profile, default the first Profile (SPEC 10.3).
private struct AddSlotSheet: View {
    let profiles: [Profile]
    let add: (URL, UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var profileId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Slot").font(.headline)
            Form {
                TextField("URL:", text: $url, prompt: Text("mail.google.com"))
                Picker("Profile:", selection: $profileId) {
                    ForEach(profiles) { Text($0.name).tag(Optional($0.id)) }
                }
            }
            if !url.trimmingCharacters(in: .whitespaces).isEmpty, slotURL(from: url) == nil {
                Text("Enter an http or https address.")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    guard let parsed = slotURL(from: url), let profileId else { return }
                    add(parsed, profileId)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(slotURL(from: url) == nil || profileId == nil)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear { profileId = profiles.first?.id }
    }
}
