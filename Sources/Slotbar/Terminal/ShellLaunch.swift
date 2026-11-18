import Foundation

/// How a Terminal tab's shell is spawned (Terminal spec, Terminal controller).
struct ShellLaunch: Equatable {
    var executable: String
    /// argv[0]: the executable's name prefixed with `-`, which makes it a login shell.
    var execName: String
    var directory: String
    /// `KEY=value` pairs.
    var environment: [String]
}

/// `shellPath` nil uses `$SHELL`, then `/bin/zsh`; `startDirectory` nil is home, a leading `~` expands to home.
/// The app environment is inherited with `TERM=xterm-256color`.
func shellLaunch(shellPath: String?, startDirectory: String?, environment: [String: String], home: String) -> ShellLaunch {
    let shell = [shellPath, environment["SHELL"]].compactMap { $0 }.first { !$0.isEmpty } ?? "/bin/zsh"
    var directory = startDirectory ?? home
    if directory == "~" || directory.hasPrefix("~/") { directory = home + directory.dropFirst() }
    var env = environment
    env["TERM"] = "xterm-256color"
    return ShellLaunch(executable: shell,
                       execName: "-" + (shell as NSString).lastPathComponent,
                       directory: directory,
                       environment: env.map { "\($0.key)=\($0.value)" })
}

/// Why a shell cannot start from these already-expanded paths, or nil when it can (Terminal spec, Terminal controller).
func shellStartError(executable: String, directory: String) -> String? {
    let files = FileManager.default
    var isDirectory: ObjCBool = false
    if !files.fileExists(atPath: executable, isDirectory: &isDirectory) {
        return "Cannot start shell \(executable): no such file"
    }
    if isDirectory.boolValue { return "Cannot start shell \(executable): is a directory" }
    if !files.isExecutableFile(atPath: executable) { return "Cannot start shell \(executable): not executable" }
    if !files.fileExists(atPath: directory, isDirectory: &isDirectory) || !isDirectory.boolValue {
        return "Starting directory \(directory) does not exist"
    }
    return nil
}
