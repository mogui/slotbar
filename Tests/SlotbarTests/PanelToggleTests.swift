import Testing
@testable import Slotbar

@Suite struct PanelToggleTests {
    @Test func hiddenPanelIsShownAndMadeKey() {
        #expect(PanelToggle().toggle(isVisible: false, isKey: false) == .show)
    }

    @Test func shownButNotKeyPanelIsMadeKeyNotHidden() {
        #expect(PanelToggle().toggle(isVisible: true, isKey: false) == .makeKey)
    }

    @Test func keyPanelIsHidden() {
        #expect(PanelToggle().toggle(isVisible: true, isKey: true) == .hide)
    }

    @Test func statusClickOnKeyPanelHidesEvenIfTheClickResignedKey() {
        var toggle = PanelToggle()
        toggle.statusMouseDown(isVisible: true, isKey: true)
        #expect(toggle.statusMouseUp() == .hide)
    }

    @Test func statusClickOnHiddenPanelShowsIt() {
        var toggle = PanelToggle()
        toggle.statusMouseDown(isVisible: false, isKey: false)
        #expect(toggle.statusMouseUp() == .show)
    }

    @Test func autoHideHidesWhenFocusMovesToAnotherApp() {
        #expect(PanelToggle().shouldAutoHide(enabled: true, newKeyWindowIsSlotbars: false))
    }

    @Test func autoHideIgnoresSlotbarsOwnWindows() {
        #expect(!PanelToggle().shouldAutoHide(enabled: true, newKeyWindowIsSlotbars: true))
    }

    @Test func autoHideOffNeverHides() {
        #expect(!PanelToggle().shouldAutoHide(enabled: false, newKeyWindowIsSlotbars: false))
    }

    @Test func resignKeyCausedByTheStatusClickIsIgnored() {
        var toggle = PanelToggle()
        toggle.statusMouseDown(isVisible: true, isKey: true)
        #expect(!toggle.shouldAutoHide(enabled: true, newKeyWindowIsSlotbars: false))
        _ = toggle.statusMouseUp()
        #expect(toggle.shouldAutoHide(enabled: true, newKeyWindowIsSlotbars: false))
    }

    @Test func terminalHotkeyOnHiddenPanelShowsTheTerminal() {
        #expect(PanelToggle().terminalToggle(isVisible: false, isKey: false, terminalShown: false) == .show)
    }

    @Test func terminalHotkeyOnASlotSwitchesToTheTerminal() {
        #expect(PanelToggle().terminalToggle(isVisible: true, isKey: true, terminalShown: false) == .show)
        #expect(PanelToggle().terminalToggle(isVisible: true, isKey: false, terminalShown: false) == .show)
    }

    @Test func terminalHotkeyOnSettingsSwitchesToTheTerminal() {
        // Settings shown: the Terminal is not the shown view even when it was the last active one.
        #expect(PanelToggle().terminalToggle(isVisible: true, isKey: true, terminalShown: false) == .show)
    }

    @Test func terminalHotkeyOnTerminalNotKeyMakesKey() {
        #expect(PanelToggle().terminalToggle(isVisible: true, isKey: false, terminalShown: true) == .makeKey)
    }

    @Test func terminalHotkeyOnKeyTerminalHides() {
        #expect(PanelToggle().terminalToggle(isVisible: true, isKey: true, terminalShown: true) == .hide)
    }
}
