import AppKit
import SwiftTerm

private let log = Log.logger("Terminal")

/// The Terminal: one tab running a login shell in a pty (Terminal spec, Terminal controller).
/// Owned by the AppDelegate while the Terminal is on; never unloaded, so the shell keeps running while hidden.
@MainActor
final class TerminalController: NSObject, LocalProcessTerminalViewDelegate {
    private let settingsStore: SettingsStore
    private let terminalView = ShellTerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    /// A shell that exits sooner than this after its spawn failed to start; later exits are normal shell exits.
    private static let startFailureWindow: TimeInterval = 2
    private var spawnedAt = Date.distantPast
    private var spawnedShell = ""

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init()
        terminalView.processDelegate = self
        terminalView.font = .monospacedSystemFont(ofSize: settingsStore.settings.terminal.fontSize, weight: .regular)
        spawnShell()
    }

    /// The active tab's view; it is also the view to make first responder.
    var view: NSView { terminalView }

    /// Terminates the shell; called when the Terminal is turned off.
    func terminate() {
        terminalView.processDelegate = nil
        terminalView.terminate()
    }

    private func spawnShell() {
        let terminal = settingsStore.settings.terminal
        let launch = shellLaunch(shellPath: terminal.shellPath, startDirectory: terminal.startDirectory,
                                 environment: ProcessInfo.processInfo.environment,
                                 home: FileManager.default.homeDirectoryForCurrentUser.path)
        if let error = shellStartError(executable: launch.executable, directory: launch.directory) {
            showStartFailure(error)
            return
        }
        log.info("Spawning \(launch.executable, privacy: .public)")
        spawnedAt = Date()
        spawnedShell = launch.executable
        terminalView.startProcess(executable: launch.executable, environment: launch.environment,
                                  execName: launch.execName, currentDirectory: launch.directory)
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    /// Leaves the error and the retry hint in the tab; Return respawns with the current settings.
    private func showStartFailure(_ error: String) {
        log.error("Shell start failed: \(error, privacy: .public)")
        terminalView.feed(text: "\(error)\r\n\r\nPress Return to try again\r\n")
        terminalView.onRetry = { [weak self] in
            guard let self else { return }
            terminalView.onRetry = nil
            terminalView.resetToInitialState()
            spawnShell()
        }
    }

    func processFailedToStart(source: TerminalView, error: LocalProcessError) {
        showStartFailure("Cannot start shell: \(error)")
    }

    /// The last (only) tab's shell exited: a fresh shell replaces it, the Panel stays as it is.
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        if Date().timeIntervalSince(spawnedAt) < Self.startFailureWindow {
            showStartFailure(exitCode.map { "Shell \(spawnedShell) exited with code \($0) at start" }
                ?? "Shell \(spawnedShell) was killed by a signal at start")
            return
        }
        log.info("Shell exited (\(exitCode.map(String.init) ?? "signal", privacy: .public)); respawning")
        terminalView.resetToInitialState()
        spawnShell()
    }
}

/// While `onRetry` is set (a failed start), Return retries and every other key is dropped.
private final class ShellTerminalView: LocalProcessTerminalView {
    var onRetry: (() -> Void)?

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        guard let onRetry else { return super.send(source: source, data: data) }
        if data.contains(13) { onRetry() }
    }
}
