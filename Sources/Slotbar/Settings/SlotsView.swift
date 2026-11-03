import SwiftUI

/// Settings, Slots section (SPEC 10.3): one card per Slot in list order, edited inline; "+" in the header,
/// move and delete in each row's menu.
struct SlotsView: View {
    let store: SettingsStore
    let favicons: FaviconCache
    @State private var adding = false

    var body: some View {
        Section {
            let slots = store.settings.slots
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                SlotRow(store: store, slot: slot, icon: favicons.image(for: slot.id),
                        canMoveUp: index > 0, canMoveDown: index < slots.count - 1) { offset in
                    store.update { $0.moveSlots(fromOffsets: IndexSet(integer: index),
                                                toOffset: offset < 0 ? index - 1 : index + 2) }
                }
            }
            if slots.isEmpty {
                Text(store.settings.profiles.isEmpty ? "Add a Profile first" : "No Slots")
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Slots")
                Spacer()
                Button { adding = true } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .disabled(store.settings.profiles.isEmpty)
                    .help(store.settings.profiles.isEmpty ? "Add a Profile first" : "Add Slot")
            }
        }
        .sheet(isPresented: $adding) {
            AddSlotSheet(profiles: store.settings.profiles) { url, profileId in
                store.update { $0.addSlot(id: UUID(), url: url, profileId: profileId) }
            }
        }
    }
}

private struct SlotRow: View {
    let store: SettingsStore
    let slot: Slot
    let icon: NSImage?
    let canMoveUp: Bool
    let canMoveDown: Bool
    /// -1 moves the Slot up one place, +1 down.
    let move: (Int) -> Void
    @State private var label = ""
    @State private var url = ""
    @FocusState private var focus: Field?

    private enum Field { case label, url }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            iconView
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 4) {
                TextField("Label", text: $label, prompt: Text(slot.url.host() ?? ""))
                    .textFieldStyle(.plain)
                    .fontWeight(.medium)
                    .focused($focus, equals: .label)
                    .onSubmit(commitLabel)
                TextField("URL", text: $url)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .focused($focus, equals: .url)
                    .onSubmit(commitURL)
                HStack(spacing: 16) {
                    Picker("Profile", selection: Binding(
                        get: { slot.profileId },
                        set: { id in if id != slot.profileId { store.update { $0.setProfile(slot: slot.id, to: id) } } }
                    )) {
                        ForEach(store.settings.profiles) { Text($0.name).tag($0.id) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    Toggle("Keep-alive", isOn: binding(\.keepAlive))
                    Toggle("Notifications", isOn: binding(\.notifications))
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .padding(.top, 2)
            }
            Menu {
                Button("Move Up") { move(-1) }.disabled(!canMoveUp)
                Button("Move Down") { move(1) }.disabled(!canMoveDown)
                Divider()
                Button("Delete", role: .destructive) { store.update { $0.deleteSlot(slot.id) } }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.vertical, 4)
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
