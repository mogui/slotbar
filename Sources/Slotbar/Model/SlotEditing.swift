import Foundation

/// A Slot URL typed in Settings (SPEC 10.3): absolute `http`/`https` with a host; a bare host gets `https://`.
func slotURL(from input: String) -> URL? {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, !text.contains(where: \.isWhitespace) else { return nil }
    // No "://": a bare host. "mailto:a@b.com" would parse as user "mailto" at host "b.com", hence the user check.
    let candidate = text.contains("://") ? text : "https://" + text
    guard let components = URLComponents(string: candidate),
          let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
          components.user == nil,
          let host = components.host, !host.isEmpty else { return nil }
    return components.url
}

extension Settings {
    /// Appends a Slot with Keep-alive and Notifications on and a null label (SPEC 10.3).
    mutating func addSlot(id: UUID, url: URL, profileId: UUID) {
        slots.append(Slot(id: id, url: url, profileId: profileId, label: nil, keepAlive: true, notifications: true))
    }

    /// Drag and drop in the Slots list; `destination` is an index in the list before the move (SwiftUI `onMove`).
    mutating func moveSlots(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moved = source.map { slots[$0] }
        let before = source.filter { $0 < destination }.count
        slots = slots.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        slots.insert(contentsOf: moved, at: destination - before)
    }

    /// A blank label is stored as null, so the next load sets the auto-label again (SPEC 10.3).
    mutating func setLabel(slot id: UUID, to text: String) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].label = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }

    /// Label and position are kept (SPEC 10.3).
    mutating func setURL(slot id: UUID, to url: URL) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].url = url
    }

    /// Label and position are kept (SPEC 10.3).
    mutating func setProfile(slot id: UUID, to profileId: UUID) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].profileId = profileId
    }

    mutating func deleteSlot(_ id: UUID) {
        slots.removeAll { $0.id == id }
    }
}
