import AppKit
import SwiftTerm

private let log = Log.logger("Terminal")

/// The Terminal: tabs each running a login shell in a pty (Terminal spec, Terminal controller). Performs the
/// effects of the TerminalSession. Owned by the AppDelegate while the Terminal is on; never unloaded, so
/// shells keep running while hidden.
@MainActor
final class TerminalController: NSObject, LocalProcessTerminalViewDelegate {
    private let settingsStore: SettingsStore
    private var session = TerminalSession()
    private var tabViews: [Int: ShellTerminalView] = [:]
    private var theme: TerminalSettings.Theme
    /// The Settings font size last applied; a change resets the live size.
    private var settingsFontSize: Double
    /// The live font size shared by all tabs; never saved.
    private var fontSize: Double
    /// An exit sooner than this after the spawn may be a start failure (`isStartFailure`); later exits are shell exits.
    private static let startFailureWindow: TimeInterval = 2
    /// Hosts the active tab's view; the Panel shows this.
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    private let tabBar = TerminalTabBarView()
    /// Closing the last tab hides the Panel.
    var onHidePanel: (() -> Void)?
    /// `anyBell` changed (the Rail's Terminal dot).
    var onBellChange: (() -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        let terminal = settingsStore.settings.terminal
        theme = terminal.theme
        settingsFontSize = terminal.fontSize
        fontSize = terminal.fontSize
        super.init()
        view.autoresizesSubviews = true
        tabBar.autoresizingMask = [.width, .minYMargin]
        tabBar.onSelect = { [weak self] id in self?.selectTab(id) }
        tabBar.onClose = { [weak self] id in self?.closeTab(id) }
        tabBar.onNewTab = { [weak self] in self?.openTab() }
        perform(session.tabs.map { .spawnShell($0.id) })
    }

    /// The active tab's view, which takes the keyboard while the Terminal is visible.
    var activeTabView: NSView? { tabViews[session.activeTab] }

    /// Terminates every shell; called when the Terminal is turned off.
    func terminate() {
        tabViews.keys.forEach(discard)
    }

    /// Stops the tab's shell without reporting its exit and drops its view.
    private func discard(_ id: Int) {
        guard let tab = tabViews.removeValue(forKey: id) else { return }
        tab.processDelegate = nil
        tab.terminate()
        tab.removeFromSuperview()
    }

    /// Turning off or quitting: asks once when any tab is busy, then terminates every shell.
    /// False when the user cancels; the shells keep running.
    func confirmTurnOff() -> Bool {
        handle(.turnedOff(busy: Set(tabViews.filter { $0.value.isBusy }.keys)))
        return tabViews.isEmpty
    }

    /// Applies the Settings theme and font size to every tab; a new Settings size replaces the live size.
    func apply(_ settings: TerminalSettings) {
        // Every Settings write lands here; restyling forces a full redraw of each tab.
        guard settings.theme != theme || settings.fontSize != settingsFontSize else { return }
        theme = settings.theme
        if settings.fontSize != settingsFontSize {
            settingsFontSize = settings.fontSize
            fontSize = settings.fontSize
        }
        tabViews.values.forEach(style)
    }

    func changeFontSize(_ change: FontSizeChange) {
        fontSize = liveFontSize(fontSize, change, settingsSize: settingsFontSize)
        tabViews.values.forEach(style)
    }

    /// Font, then the theme palette; `system` follows the tab's effective appearance.
    private func style(_ tab: ShellTerminalView) {
        if tab.font.pointSize != fontSize { tab.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
        let dark = tab.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let palette = terminalPalette(theme: theme, dark: dark)
        tab.installColors(palette.ansi.map {
            Color(red8: UInt16($0 >> 16 & 0xff), green8: UInt16($0 >> 8 & 0xff), blue8: UInt16($0 & 0xff))
        })
        tab.nativeForegroundColor = nsColor(palette.foreground)
        tab.nativeBackgroundColor = nsColor(palette.background)
        tab.caretColor = nsColor(palette.cursor)
        tab.selectedTextBackgroundColor = nsColor(palette.selection)
        tab.selectedTextForegroundColor = nsColor(palette.foreground)
    }

    private func nsColor(_ rgb: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat(rgb >> 16 & 0xff) / 255, green: CGFloat(rgb >> 8 & 0xff) / 255,
                blue: CGFloat(rgb & 0xff) / 255, alpha: 1)
    }

    func openTab() { handle(.openTab) }
    func selectNextTab() { handle(.selectNext) }
    func selectPreviousTab() { handle(.selectPrevious) }

    func selectTab(_ id: Int) { handle(.select(id)) }
    func closeActiveTab() { closeTab(session.activeTab) }

    func closeTab(_ id: Int) {
        handle(.closeRequested(id, busy: tabViews[id]?.isBusy ?? false))
    }

    /// Clears the active tab's screen and scrollback in the view; a shell at its prompt gets Ctrl+L to redraw it.
    func clearActiveTab() {
        guard let tab = tabViews[session.activeTab] else { return }
        tab.feed(text: "\u{1b}[3J\u{1b}[2J\u{1b}[H")
        if !tab.isBusy && tab.onRetry == nil { tab.send([0x0c]) }
    }

    func setShown(_ shown: Bool) {
        if shown != session.isShown { handle(.shown(shown)) }
    }

    /// Some tab rang the bell while not visible.
    var anyBell: Bool { session.anyBell }

    private func handle(_ event: TerminalSession.Event) {
        let hadBell = session.anyBell
        perform(session.handle(event))
        if session.anyBell != hadBell { onBellChange?() }
    }

    private func perform(_ effects: [TerminalSession.Effect]) {
        for effect in effects {
            switch effect {
            case .spawnShell(let id): spawnTab(id)
            case .terminateShell(let id): discard(id)
            case .askConfirmation(let id): askToClose(id)
            case .hidePanel: onHidePanel?()
            case .askTurnOffConfirmation(let ids):
                if askToTurnOff(ids) { perform(session.handle(.turnOffConfirmed)) }
            }
        }
        showActiveTab()
    }

    /// Puts the tab bar (two or more tabs) and the active tab's view in the container and gives the tab
    /// the keyboard if the Terminal is on screen.
    private func showActiveTab() {
        let items = terminalTabBar(tabs: session.tabs, activeTab: session.activeTab, fallbackTitle: shellName)
        tabBar.update(items: items)
        let barHeight = items.isEmpty ? 0 : TerminalTabBarView.height
        if items.isEmpty {
            tabBar.removeFromSuperview()
        } else if tabBar.superview == nil {
            tabBar.frame = NSRect(x: 0, y: view.bounds.height - barHeight, width: view.bounds.width, height: barHeight)
            view.addSubview(tabBar)
        }
        guard let active = tabViews[session.activeTab] else { return }
        if active.superview !== view {
            view.subviews.filter { $0 !== tabBar }.forEach { $0.removeFromSuperview() }
            active.autoresizingMask = [.width, .height]
            view.addSubview(active)
            style(active)
        }
        active.frame = NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - barHeight)
        view.window?.makeFirstResponder(active)
    }

    private func spawnTab(_ id: Int) {
        var options = TerminalOptions.default
        options.scrollback = 10_000
        options.cursorStyle = .blinkBlock
        let tab = ShellTerminalView(frame: view.bounds, font: .monospacedSystemFont(ofSize: fontSize, weight: .regular),
                                    options: options)
        tab.processDelegate = self
        tab.optionAsMetaKey = false // Option composes characters (e.g. "@", "[" on an Italian layout)
        style(tab)
        tab.onAppearanceChange = { [weak self, weak tab] in
            if let self, let tab { style(tab) }
        }
        tab.onBell = { [weak self] in self?.handle(.bell(id)) }
        tabViews[id] = tab
        spawnShell(in: tab)
    }

    private func spawnShell(in tab: ShellTerminalView) {
        let terminal = settingsStore.settings.terminal
        let launch = shellLaunch(shellPath: terminal.shellPath, startDirectory: terminal.startDirectory,
                                 environment: ProcessInfo.processInfo.environment,
                                 home: FileManager.default.homeDirectoryForCurrentUser.path)
        tab.spawnedShell = launch.executable
        if let error = shellStartError(executable: launch.executable, directory: launch.directory) {
            showStartFailure(error, in: tab)
            return
        }
        log.info("Spawning \(launch.executable, privacy: .public)")
        tab.spawnedAt = Date()
        tab.startProcess(executable: launch.executable, environment: launch.environment,
                         execName: launch.execName, currentDirectory: launch.directory)
    }

    /// Leaves the error and the retry hint in the tab; Return respawns with the current settings.
    private func showStartFailure(_ error: String, in tab: ShellTerminalView) {
        log.error("Shell start failed: \(error, privacy: .public)")
        tab.feed(text: "\(error)\r\n\r\nPress Return to try again\r\n")
        tab.onRetry = { [weak self, weak tab] in
            guard let self, let tab else { return }
            tab.onRetry = nil
            tab.resetToInitialState()
            spawnShell(in: tab)
        }
    }

    private func askToClose(_ id: Int) {
        guard let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = "Close this tab?"
        alert.informativeText = "A process is running in this tab. Closing the tab terminates it."
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self] response in
            MainActor.assumeIsolated {
                if response == .alertFirstButtonReturn { self?.handle(.closeConfirmed(id)) }
            }
        }
    }

    /// One app-modal alert for turn-off and Quit; Quit can come from the status menu with the Panel hidden.
    private func askToTurnOff(_ ids: [Int]) -> Bool {
        // Same names as the tab bar: the shell-set title, else the tab's shell name.
        let titles = ids.map { id in
            let title = session.tabs.first { $0.id == id }?.title ?? ""
            return title.isEmpty ? shellName(id) : title
        }
        let alert = NSAlert()
        alert.messageText = "Terminate running processes?"
        alert.informativeText = "A process is running in these tabs:\n\(titles.joined(separator: "\n"))\nThey will be terminated."
        alert.addButton(withTitle: "Terminate")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// A tab's name when its shell set no title.
    private func shellName(_ id: Int) -> String {
        URL(fileURLWithPath: tabViews[id]?.spawnedShell ?? "").lastPathComponent
    }

    private func tabId(_ source: AnyObject) -> Int? {
        tabViews.first { $0.value === source }?.key
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        if let id = tabId(source) { handle(.titleChanged(id, title)) }
    }

    func processFailedToStart(source: TerminalView, error: LocalProcessError) {
        guard let tab = source as? ShellTerminalView else { return }
        showStartFailure("Cannot start shell: \(error)", in: tab)
    }

    /// A start failure leaves the tab showing the error; a shell exit goes to the session model.
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        guard let tab = source as? ShellTerminalView, let id = tabId(tab) else { return }
        if isStartFailure(exitCode: exitCode,
                          withinStartWindow: Date().timeIntervalSince(tab.spawnedAt) < Self.startFailureWindow,
                          isLastTab: session.tabs.count == 1) {
            showStartFailure(exitCode.map { "Shell \(tab.spawnedShell) exited with code \($0) at start" }
                ?? "Shell \(tab.spawnedShell) was killed by a signal at start", in: tab)
            return
        }
        log.info("Shell exited (\(exitCode.map(String.init) ?? "signal", privacy: .public))")
        tab.processDelegate = nil
        tab.removeFromSuperview()
        tabViews[id] = nil
        handle(.shellExited(id))
    }
}

/// One tab. While `onRetry` is set (a failed start), Return retries and every other key is dropped.
private final class ShellTerminalView: LocalProcessTerminalView {
    var onRetry: (() -> Void)?
    var onAppearanceChange: (() -> Void)?
    var onBell: (() -> Void)?
    var spawnedAt = Date.distantPast
    var spawnedShell = ""

    /// A foreground process other than the shell: the pty's foreground process group differs from the shell's pid.
    var isBusy: Bool {
        guard process.running, process.childfd >= 0 else { return false }
        let group = tcgetpgrp(process.childfd)
        return group > 0 && group != process.shellPid
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }

    /// Called on SwiftTerm's read thread for every BEL; SwiftTerm still beeps.
    nonisolated override func bell(source: Terminal) {
        super.bell(source: source)
        Task { @MainActor [weak self] in self?.onBell?() }
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        guard let onRetry else { return super.send(source: source, data: data) }
        if data.contains(13) { onRetry() }
    }
}
