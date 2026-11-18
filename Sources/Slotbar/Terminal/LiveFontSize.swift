/// `Cmd+=` / `Cmd+-` / `Cmd+0` in the Terminal (Terminal spec, Keyboard).
enum FontSizeChange: Sendable {
    case larger, smaller, reset
}

/// The live font size shared by all tabs after a change: 1 pt steps within 9-36, reset to the Settings size. Never saved.
func liveFontSize(_ current: Double, _ change: FontSizeChange, settingsSize: Double) -> Double {
    let range = TerminalSettings.fontSizeRange
    switch change {
    case .larger: return min(current + 1, range.upperBound)
    case .smaller: return max(current - 1, range.lowerBound)
    case .reset: return settingsSize
    }
}
