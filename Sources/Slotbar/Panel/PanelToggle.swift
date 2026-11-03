/// Toggle and auto-hide decisions (SPEC 4.5). `isKey` is true when the Panel or one of its Child windows is key.
struct PanelToggle {
    enum Action: Equatable { case show, makeKey, hide }

    /// Panel state recorded at status icon mouse-down; non-nil while the click is in progress.
    private var statusClickState: (isVisible: Bool, isKey: Bool)?

    func toggle(isVisible: Bool, isKey: Bool) -> Action {
        if !isVisible { return .show }
        return isKey ? .hide : .makeKey
    }

    mutating func statusMouseDown(isVisible: Bool, isKey: Bool) {
        statusClickState = (isVisible, isKey)
    }

    /// Toggles from the state recorded at mouse-down, so a click never hides and re-shows.
    mutating func statusMouseUp() -> Action? {
        guard let state = statusClickState else { return nil }
        statusClickState = nil
        return toggle(isVisible: state.isVisible, isKey: state.isKey)
    }

    /// Called when a Slotbar window resigns key. The resign-key caused by a status click is ignored.
    func shouldAutoHide(enabled: Bool, newKeyWindowIsSlotbars: Bool) -> Bool {
        enabled && !newKeyWindowIsSlotbars && statusClickState == nil
    }
}
