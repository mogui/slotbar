import Testing
@testable import Slotbar

@Suite struct ShellLaunchTests {
    let home = "/Users/ada"

    @Test func nullShellPathUsesTheShellEnvironmentVariable() {
        let launch = shellLaunch(shellPath: nil, startDirectory: nil, environment: ["SHELL": "/bin/bash"], home: home)
        #expect(launch.executable == "/bin/bash")
        #expect(launch.execName == "-bash")
    }

    @Test func missingShellFallsBackToZsh() {
        #expect(shellLaunch(shellPath: nil, startDirectory: nil, environment: [:], home: home).executable == "/bin/zsh")
        #expect(shellLaunch(shellPath: nil, startDirectory: nil, environment: ["SHELL": ""], home: home).executable == "/bin/zsh")
    }

    @Test func explicitShellPathWinsOverShell() {
        let launch = shellLaunch(shellPath: "/opt/homebrew/bin/fish", startDirectory: nil,
                                 environment: ["SHELL": "/bin/zsh"], home: home)
        #expect(launch.executable == "/opt/homebrew/bin/fish")
        #expect(launch.execName == "-fish")
    }

    @Test func loginShellArgv0IsPrefixedWithDash() {
        #expect(shellLaunch(shellPath: "/bin/zsh", startDirectory: nil, environment: [:], home: home).execName == "-zsh")
    }

    @Test func nullStartDirectoryIsHome() {
        #expect(shellLaunch(shellPath: nil, startDirectory: nil, environment: [:], home: home).directory == "/Users/ada")
    }

    @Test func leadingTildeExpandsToHome() {
        #expect(shellLaunch(shellPath: nil, startDirectory: "~/src", environment: [:], home: home).directory == "/Users/ada/src")
        #expect(shellLaunch(shellPath: nil, startDirectory: "~", environment: [:], home: home).directory == "/Users/ada")
        #expect(shellLaunch(shellPath: nil, startDirectory: "/tmp/~x", environment: [:], home: home).directory == "/tmp/~x")
    }

    @Test func environmentIsInheritedWithTermOverridden() {
        let launch = shellLaunch(shellPath: nil, startDirectory: nil,
                                 environment: ["PATH": "/usr/bin", "TERM": "dumb"], home: home)
        #expect(Set(launch.environment) == ["PATH=/usr/bin", "TERM=xterm-256color"])
    }
}
