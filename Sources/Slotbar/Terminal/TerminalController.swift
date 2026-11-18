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
    /// A shell that exits sooner than this after its spawn failed to start; later exits are normal shell exits.
    private static let startFailureWindow: TimeInterval = 2
    /// Hosts the active tab's view; the Panel shows this.
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    /// Closing the last tab hides the Panel.
    var onHidePanel: (() -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init()
        view.autoresizesSubviews = true
        perform(session.tabs.map { .spawnShell($0.id) })
    }

    /// The active tab's view, which takes the keyboard while the Terminal is visible.
    var activeTabView: NSView? { tabViews[session.activeTab] }

    /// Terminates every shell; called when the Terminal is turned off.
    func terminate() {
        for tab in tabViews.values {
            tab.processDelegate = nil
            tab.terminate()
        }
        tabViews = [:]
    }

    func openTab() { handle(.openTab) }
    func selectNextTab() { handle(.selectNext) }
    func selectPreviousTab() { handle(.selectPrevious) }

    func closeActiveTab() {
        let id = session.activeTab
        handle(.closeRequested(id, busy: tabViews[id]?.isBusy ?? false))
    }

    func setShown(_ shown: Bool) {
        if shown != session.isShown { handle(.shown(shown)) }
    }

    private func handle(_ event: TerminalSession.Event) {
        perform(session.handle(event))
    }

    private func perform(_ effects: [TerminalSession.Effect]) {
        for effect in effects {
            switch effect {
            case .spawnShell(let id): spawnTab(id)
            case .terminateShell(let id):
                guard let tab = tabViews.removeValue(forKey: id) else { break }
                tab.processDelegate = nil
                tab.terminate()
                tab.removeFromSuperview()
            case .askConfirmation(let id): askToClose(id)
            case .hidePanel: onHidePanel?()
            }
        }
        showActiveTab()
    }

    /// Puts the active tab's view in the container and gives it the keyboard if the Terminal is on screen.
    private func showActiveTab() {
        guard let active = tabViews[session.activeTab] else { return }
        if active.superview !== view {
            view.subviews.forEach { $0.removeFromSuperview() }
            active.frame = view.bounds
            active.autoresizingMask = [.width, .height]
            view.addSubview(active)
        }
        view.window?.makeFirstResponder(active)
    }

    private func spawnTab(_ id: Int) {
        let tab = ShellTerminalView(frame: view.bounds)
        tab.processDelegate = self
        tab.font = .monospacedSystemFont(ofSize: settingsStore.settings.terminal.fontSize, weight: .regular)
        tabViews[id] = tab
        spawnShell(in: tab)
    }

    private func spawnShell(in tab: ShellTerminalView) {
        let terminal = settingsStore.settings.terminal
        let launch = shellLaunch(shellPath: terminal.shellPath, startDirectory: terminal.startDirectory,
                                 environment: ProcessInfo.processInfo.environment,
                                 home: FileManager.default.homeDirectoryForCurrentUser.path)
        if let error = shellStartError(executable: launch.executable, directory: launch.directory) {
            showStartFailure(error, in: tab)
            return
        }
        log.info("Spawning \(launch.executable, privacy: .public)")
        tab.spawnedAt = Date()
        tab.spawnedShell = launch.executable
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

    /// An exit soon after the spawn is a start failure (the tab stays, showing the error); later it is a shell exit.
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        guard let tab = source as? ShellTerminalView, let id = tabId(tab) else { return }
        if Date().timeIntervalSince(tab.spawnedAt) < Self.startFailureWindow {
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
    var spawnedAt = Date.distantPast
    var spawnedShell = ""

    /// A foreground process other than the shell: the pty's foreground process group differs from the shell's pid.
    var isBusy: Bool {
        guard process.running, process.childfd >= 0 else { return false }
        let group = tcgetpgrp(process.childfd)
        return group > 0 && group != process.shellPid
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        guard let onRetry else { return super.send(source: source, data: data) }
        if data.contains(13) { onRetry() }
    }
}
