/// The Terminal's tabs as a pure value (Terminal spec, Terminal session model): events in, effects out
/// for the TerminalController to perform. Never holds zero tabs.
struct TerminalSession: Sendable {
    struct Tab: Equatable, Sendable {
        let id: Int
        var title = ""
        /// The tab rang the bell while not visible.
        var bell = false
    }

    enum Event: Equatable, Sendable {
        case openTab
        case select(Int)
        case selectNext
        case selectPrevious
        /// `busy`: the pty's foreground process group differs from the shell's pid.
        case closeRequested(Int, busy: Bool)
        case closeConfirmed(Int)
        case shellExited(Int)
        case titleChanged(Int, String)
        case bell(Int)
        /// The Terminal became visible (Panel shown on it) or stopped being visible.
        case shown(Bool)
        /// The Terminal is being turned off or Slotbar quits; `busy`: the tabs running a foreground process.
        case turnedOff(busy: Set<Int>)
        case turnOffConfirmed
    }

    enum Effect: Equatable, Sendable {
        case spawnShell(Int)
        case terminateShell(Int)
        case askConfirmation(Int)
        case hidePanel
        /// One confirmation listing these busy tabs, in tab order.
        case askTurnOffConfirmation([Int])
    }

    private(set) var tabs = [Tab(id: 0)]
    private(set) var activeTab = 0
    private(set) var isShown = false
    private var nextId = 1

    /// Some tab rang the bell while not visible (the Rail's Terminal dot).
    var anyBell: Bool { tabs.contains(where: \.bell) }

    /// A bell flags its tab unless the tab is visible; the visible tab's flag is cleared after every event.
    mutating func handle(_ event: Event) -> [Effect] {
        defer {
            if isShown, let i = index(of: activeTab) { tabs[i].bell = false }
        }
        switch event {
        case .openTab:
            let tab = newTab()
            tabs.append(tab)
            activeTab = tab.id
            return [.spawnShell(tab.id)]
        case .select(let id):
            if index(of: id) != nil { activeTab = id }
            return []
        case .selectNext: return moveActive(by: 1)
        case .selectPrevious: return moveActive(by: -1)
        case .closeRequested(let id, let busy):
            if busy && index(of: id) != nil { return [.askConfirmation(id)] }
            return remove(id, closedByUser: true)
        case .closeConfirmed(let id): return remove(id, closedByUser: true)
        case .shellExited(let id): return remove(id, closedByUser: false)
        case .titleChanged(let id, let title):
            if let i = index(of: id) { tabs[i].title = title }
            return []
        case .bell(let id):
            if let i = index(of: id) { tabs[i].bell = true }
            return []
        case .shown(let shown):
            isShown = shown
            return []
        case .turnedOff(let busy):
            let busyTabs = tabs.map(\.id).filter(busy.contains)
            return busyTabs.isEmpty ? tabs.map { .terminateShell($0.id) } : [.askTurnOffConfirmation(busyTabs)]
        case .turnOffConfirmed:
            return tabs.map { .terminateShell($0.id) }
        }
    }

    /// Closing the last tab replaces it and hides the Panel; a shell exit on the last tab replaces it only.
    private mutating func remove(_ id: Int, closedByUser: Bool) -> [Effect] {
        guard let i = index(of: id) else { return [] }
        var effects: [Effect] = closedByUser ? [.terminateShell(id)] : []
        if tabs.count == 1 {
            let tab = newTab()
            tabs = [tab]
            activeTab = tab.id
            effects.append(.spawnShell(tab.id))
            if closedByUser { effects.append(.hidePanel) }
        } else {
            tabs.remove(at: i)
            if activeTab == id { activeTab = tabs[min(i, tabs.count - 1)].id }
        }
        return effects
    }

    private func index(of id: Int) -> Int? { tabs.firstIndex { $0.id == id } }

    private mutating func moveActive(by offset: Int) -> [Effect] {
        let current = index(of: activeTab) ?? 0
        activeTab = tabs[(current + offset + tabs.count) % tabs.count].id
        return []
    }

    private mutating func newTab() -> Tab {
        defer { nextId += 1 }
        return Tab(id: nextId)
    }
}
