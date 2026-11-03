import Testing
import AppKit
@testable import Slotbar

@Suite struct PanelGeometryTests {
    @Test func rightEdgePanelSpansFullHeightAndTakesFractionOfWidth() {
        let visible = NSRect(x: 0, y: 25, width: 2000, height: 1100)
        let frame = panelFrame(visibleFrame: visible, depthFraction: 0.45)
        #expect(frame == NSRect(x: 1100, y: 25, width: 900, height: 1100))
    }

    @Test func narrowFractionIsWidenedTo480Points() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 875)
        let frame = panelFrame(visibleFrame: visible, depthFraction: 0.2)
        #expect(frame == NSRect(x: 960, y: 0, width: 480, height: 875))
    }

    @Test func wideFractionIsCappedAt95PercentOfWidth() {
        let visible = NSRect(x: 0, y: 0, width: 2000, height: 1000)
        let frame = panelFrame(visibleFrame: visible, depthFraction: 1.0)
        #expect(frame == NSRect(x: 100, y: 0, width: 1900, height: 1000))
    }

    @Test func the95PercentCapWinsOverMinimumOnTinyScreen() {
        let visible = NSRect(x: 0, y: 0, width: 400, height: 300)
        let frame = panelFrame(visibleFrame: visible, depthFraction: 0.45)
        #expect(frame == NSRect(x: 20, y: 0, width: 380, height: 300))
    }

    @Test func followsVisibleFrameOfSecondaryScreen() {
        let visible = NSRect(x: -1920, y: 200, width: 1920, height: 1080)
        let frame = panelFrame(visibleFrame: visible, depthFraction: 0.5)
        #expect(frame == NSRect(x: -960, y: 200, width: 960, height: 1080))
    }
}
