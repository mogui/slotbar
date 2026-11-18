import Testing
@testable import Slotbar

@Suite struct TerminalSessionTests {
    /// Three tabs, the last one active.
    func threeTabs() -> (TerminalSession, [Int]) {
        var session = TerminalSession()
        _ = session.handle(.openTab)
        _ = session.handle(.openTab)
        return (session, session.tabs.map(\.id))
    }

    @Test func startsWithOneActiveTab() {
        let session = TerminalSession()
        #expect(session.tabs.count == 1)
        #expect(session.activeTab == session.tabs[0].id)
        #expect(session.tabs[0].title == "")
    }

    @Test func openTabAppendsAnActiveTabAndSpawnsItsShell() {
        var session = TerminalSession()
        let first = session.activeTab
        let effects = session.handle(.openTab)
        #expect(session.tabs.count == 2)
        #expect(session.tabs[0].id == first)
        let new = session.tabs[1].id
        #expect(new != first && session.activeTab == new)
        #expect(effects == [.spawnShell(new)])
    }
}

extension TerminalSessionTests {
    @Test func selectMakesATabActiveWithNoEffects() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.select(ids[0]))
        #expect(effects.isEmpty && session.activeTab == ids[0])
    }

    @Test func selectingAnUnknownTabIsIgnored() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.select(99))
        #expect(effects.isEmpty && session.activeTab == ids[2])
    }

    @Test func nextAndPreviousMoveTheActiveTab() {
        var (session, ids) = threeTabs()
        _ = session.handle(.select(ids[1]))
        _ = session.handle(.selectNext)
        #expect(session.activeTab == ids[2])
        _ = session.handle(.selectPrevious)
        _ = session.handle(.selectPrevious)
        #expect(session.activeTab == ids[0])
    }

    @Test func nextAndPreviousWrapAround() {
        var (session, ids) = threeTabs()
        _ = session.handle(.selectNext)
        #expect(session.activeTab == ids[0])
        _ = session.handle(.selectPrevious)
        #expect(session.activeTab == ids[2])
    }

    @Test func nextAndPreviousWithOneTabChangeNothing() {
        var session = TerminalSession()
        let only = session.activeTab
        let effects = session.handle(.selectNext) + session.handle(.selectPrevious)
        #expect(effects.isEmpty && session.activeTab == only && session.tabs.count == 1)
    }
}

extension TerminalSessionTests {
    @Test func closeRequestedOnAnIdleTabClosesIt() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.closeRequested(ids[0], busy: false))
        #expect(effects == [.terminateShell(ids[0])])
        #expect(session.tabs.map(\.id) == [ids[1], ids[2]] && session.activeTab == ids[2])
    }

    @Test func closeRequestedOnABusyTabOnlyAsksForConfirmation() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.closeRequested(ids[1], busy: true))
        #expect(effects == [.askConfirmation(ids[1])])
        #expect(session.tabs.map(\.id) == ids)
    }

    @Test func closeConfirmedClosesTheTab() {
        var (session, ids) = threeTabs()
        _ = session.handle(.closeRequested(ids[1], busy: true))
        let effects = session.handle(.closeConfirmed(ids[1]))
        #expect(effects == [.terminateShell(ids[1])])
        #expect(session.tabs.map(\.id) == [ids[0], ids[2]])
    }

    @Test func closeConfirmedForAVanishedTabIsIgnored() {
        var (session, ids) = threeTabs()
        _ = session.handle(.shellExited(ids[1]))
        let effects = session.handle(.closeConfirmed(ids[1]))
        #expect(effects.isEmpty && session.tabs.map(\.id) == [ids[0], ids[2]])
    }

    @Test func closingTheActiveTabActivatesItsRightNeighbour() {
        var (session, ids) = threeTabs()
        _ = session.handle(.select(ids[1]))
        _ = session.handle(.closeRequested(ids[1], busy: false))
        #expect(session.activeTab == ids[2])
    }

    @Test func closingTheLastPositionActiveTabActivatesItsLeftNeighbour() {
        var (session, ids) = threeTabs()
        _ = session.handle(.closeRequested(ids[2], busy: false))
        #expect(session.activeTab == ids[1])
    }

    @Test func closingTheOnlyTabReplacesItAndHidesThePanel() {
        var session = TerminalSession()
        let old = session.activeTab
        let effects = session.handle(.closeRequested(old, busy: false))
        let new = session.activeTab
        #expect(session.tabs.map(\.id) == [new] && new != old)
        #expect(effects == [.terminateShell(old), .spawnShell(new), .hidePanel])
    }

    @Test func confirmedCloseOfTheOnlyTabReplacesItAndHidesThePanel() {
        var session = TerminalSession()
        let old = session.activeTab
        _ = session.handle(.closeRequested(old, busy: true))
        let effects = session.handle(.closeConfirmed(old))
        let new = session.activeTab
        #expect(session.tabs.map(\.id) == [new] && new != old)
        #expect(effects == [.terminateShell(old), .spawnShell(new), .hidePanel])
    }
}

extension TerminalSessionTests {
    @Test func shellExitClosesItsTabWithoutTerminating() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.shellExited(ids[2]))
        #expect(effects.isEmpty)
        #expect(session.tabs.map(\.id) == [ids[0], ids[1]] && session.activeTab == ids[1])
    }

    @Test func shellExitOfAnInactiveTabKeepsTheActiveTab() {
        var (session, ids) = threeTabs()
        _ = session.handle(.shellExited(ids[0]))
        #expect(session.activeTab == ids[2])
    }

    @Test func shellExitOnTheOnlyTabReplacesItWithThePanelUnchanged() {
        var session = TerminalSession()
        let old = session.activeTab
        let effects = session.handle(.shellExited(old))
        let new = session.activeTab
        #expect(session.tabs.map(\.id) == [new] && new != old)
        #expect(effects == [.spawnShell(new)])
    }

    @Test func titleChangedSetsThatTabsTitle() {
        var (session, ids) = threeTabs()
        let effects = session.handle(.titleChanged(ids[1], "vim notes.md"))
        #expect(effects.isEmpty)
        #expect(session.tabs.map(\.title) == ["", "vim notes.md", ""])
    }

    @Test func shownAndHiddenAreRecordedWithNoEffects() {
        var session = TerminalSession()
        #expect(!session.isShown)
        let shown = session.handle(.shown(true))
        #expect(shown.isEmpty && session.isShown)
        let hidden = session.handle(.shown(false))
        #expect(hidden.isEmpty && !session.isShown)
    }

    @Test func noEventSequenceLeavesZeroTabs() {
        var session = TerminalSession()
        for _ in 0..<3 {
            _ = session.handle(.closeRequested(session.activeTab, busy: false))
            _ = session.handle(.shellExited(session.activeTab))
            _ = session.handle(.closeConfirmed(session.activeTab))
        }
        #expect(session.tabs.count == 1 && session.tabs[0].id == session.activeTab)
    }
}
