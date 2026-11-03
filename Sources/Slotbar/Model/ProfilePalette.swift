/// The fixed 8-color Profile palette (SPEC 10.2).
enum ProfilePalette {
    static let colors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"), ("Purple", "#AF52DE"), ("Pink", "#FF2D55"), ("Red", "#FF3B30"),
        ("Orange", "#FF9500"), ("Yellow", "#FFCC00"), ("Green", "#34C759"), ("Graphite", "#8E8E93"),
    ]

    /// First unused palette color; when all are used, the least-used, first in palette order on ties.
    static func colorForNewProfile(existing: [Profile]) -> String {
        let used = existing.map { $0.color.uppercased() }
        let counts = colors.map { color in used.filter { $0 == color.hex }.count }
        let index = counts.indices.min { counts[$0] < counts[$1] }!
        return colors[index].hex
    }
}
