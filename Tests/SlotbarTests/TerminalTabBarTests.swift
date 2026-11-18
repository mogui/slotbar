import Testing
@testable import Slotbar

@Suite struct TerminalTabBarTests {
    @Test func oneTabHasNoBar() {
        let items = terminalTabBar(tabs: [.init(id: 0, title: "vim")], activeTab: 0) { _ in "zsh" }
        #expect(items.isEmpty)
    }

    @Test func twoOrMoreTabsShowOneItemPerTabWithTheActiveMarked() {
        let tabs: [TerminalSession.Tab] = [.init(id: 3, title: "vim"), .init(id: 5, title: "~/src"),
                                           .init(id: 8, title: "htop")]
        let items = terminalTabBar(tabs: tabs, activeTab: 5) { _ in "zsh" }
        #expect(items == [TerminalTabItem(id: 3, title: "vim", isActive: false),
                          TerminalTabItem(id: 5, title: "~/src", isActive: true),
                          TerminalTabItem(id: 8, title: "htop", isActive: false)])
    }

    @Test func untitledTabsUseTheirOwnShellsNameAsFallback() {
        let tabs: [TerminalSession.Tab] = [.init(id: 0), .init(id: 1), .init(id: 2, title: "vim")]
        let shells = [0: "zsh", 1: "fish", 2: "bash"]
        let titles = terminalTabBar(tabs: tabs, activeTab: 0) { shells[$0]! }.map(\.title)
        #expect(titles == ["zsh", "fish", "vim"])
    }
}
