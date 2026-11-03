import AppKit
import Testing
@testable import Slotbar

@Suite struct ChildWindowGeometryTests {
    let visible = NSRect(x: 0, y: 25, width: 2000, height: 1100)

    @Test func defaultSizeIsCenteredOffARightEdgePanel() {
        let panel = NSRect(x: 1100, y: 25, width: 900, height: 1100)
        #expect(childWindowFrame(width: nil, height: nil, visibleFrame: visible, panelFrame: panel)
                == NSRect(x: 150, y: 225, width: 800, height: 700))
    }

    @Test func requestedSizeIsCenteredBelowATopEdgePanel() {
        let panel = NSRect(x: 0, y: 425, width: 2000, height: 700)
        #expect(childWindowFrame(width: 500, height: 300, visibleFrame: visible, panelFrame: panel)
                == NSRect(x: 750, y: 75, width: 500, height: 300))
    }

    @Test func oversizedRequestIsClampedToTheVisibleFrame() {
        let panel = NSRect(x: 1100, y: 25, width: 900, height: 1100)
        #expect(childWindowFrame(width: 5000, height: 3000, visibleFrame: visible, panelFrame: panel)
                == NSRect(x: 0, y: 25, width: 2000, height: 1100))
    }

    @Test func windowWiderThanTheFreeAreaStaysOnScreen() {
        let panel = NSRect(x: 300, y: 25, width: 1700, height: 1100)
        #expect(childWindowFrame(width: nil, height: nil, visibleFrame: visible, panelFrame: panel)
                == NSRect(x: 0, y: 225, width: 800, height: 700))
    }

    @Test func withoutAPanelTheWindowIsCenteredOnTheVisibleFrame() {
        #expect(childWindowFrame(width: nil, height: nil, visibleFrame: visible, panelFrame: nil)
                == NSRect(x: 600, y: 225, width: 800, height: 700))
    }

    @Test func titleIsPageTitleThenProfileName() {
        #expect(childWindowTitle(pageTitle: "Compose - Gmail", profileName: "Work") == "Compose - Gmail - Work")
    }

    @Test func blankPageTitleShowsTheProfileNameOnly() {
        #expect(childWindowTitle(pageTitle: "  ", profileName: "Work") == "Work")
        #expect(childWindowTitle(pageTitle: nil, profileName: "Work") == "Work")
    }
}
