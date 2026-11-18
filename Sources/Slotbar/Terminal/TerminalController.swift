import AppKit
import SwiftTerm

private let log = Log.logger("Terminal")

/// The Terminal: one tab running a login shell in a pty (Terminal spec, Terminal controller).
/// Owned by the AppDelegate while the Terminal is on; never unloaded, so the shell keeps running while hidden.
@MainActor
final class TerminalController: NSObject, LocalProcessTerminalViewDelegate {
    private let settingsStore: SettingsStore
    private let terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))

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
        log.info("Spawning \(launch.executable, privacy: .public)")
        terminalView.startProcess(executable: launch.executable, environment: launch.environment,
                                  execName: launch.execName, currentDirectory: launch.directory)
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    /// The last (only) tab's shell exited: a fresh shell replaces it, the Panel stays as it is.
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        log.info("Shell exited (\(exitCode.map(String.init) ?? "signal", privacy: .public)); respawning")
        terminalView.resetToInitialState()
        spawnShell()
    }
}
