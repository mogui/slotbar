import Testing
import AppKit
@testable import Slotbar

@Suite struct PanelGeometryTests {
    @Test func rightEdgePanelSpansFullHeightAndTakesFractionOfWidth() {
        let visible = NSRect(x: 0, y: 25, width: 2000, height: 1100)
        let frame = panelFrame(visibleFrame: visible, edge: .right, depthFraction: 0.45)
        #expect(frame == NSRect(x: 1100, y: 25, width: 900, height: 1100))
    }

    @Test func leftEdgePanelHugsTheVisibleFrameMinX() {
        let visible = NSRect(x: 80, y: 0, width: 2000, height: 1100)
        let frame = panelFrame(visibleFrame: visible, edge: .left, depthFraction: 0.45)
        #expect(frame == NSRect(x: 80, y: 0, width: 900, height: 1100))
    }

    @Test func topEdgePanelSpansFullWidthBelowTheMenuBar() {
        let visible = NSRect(x: 0, y: 0, width: 1600, height: 1000)
        let frame = panelFrame(visibleFrame: visible, edge: .top, depthFraction: 0.7)
        #expect(frame == NSRect(x: 0, y: 300, width: 1600, height: 700))
    }

    @Test func bottomEdgePanelSitsOnTheDocksInnerEdge() {
        let visible = NSRect(x: 0, y: 70, width: 1600, height: 1000)
        let frame = panelFrame(visibleFrame: visible, edge: .bottom, depthFraction: 0.7)
        #expect(frame == NSRect(x: 0, y: 70, width: 1600, height: 700))
    }

    @Test func narrowFractionIsWidenedTo480Points() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 875)
        let frame = panelFrame(visibleFrame: visible, edge: .right, depthFraction: 0.2)
        #expect(frame == NSRect(x: 960, y: 0, width: 480, height: 875))
    }

    @Test func shallowVerticalFractionIsDeepenedTo480Points() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 875)
        let frame = panelFrame(visibleFrame: visible, edge: .top, depthFraction: 0.1)
        #expect(frame == NSRect(x: 0, y: 395, width: 1440, height: 480))
    }

    @Test func wideFractionIsCappedAt95PercentOfWidth() {
        let visible = NSRect(x: 0, y: 0, width: 2000, height: 1000)
        let frame = panelFrame(visibleFrame: visible, edge: .right, depthFraction: 1.0)
        #expect(frame == NSRect(x: 100, y: 0, width: 1900, height: 1000))
    }

    @Test func the95PercentCapWinsOverMinimumOnTinyScreen() {
        let visible = NSRect(x: 0, y: 0, width: 400, height: 300)
        let frame = panelFrame(visibleFrame: visible, edge: .right, depthFraction: 0.45)
        #expect(frame == NSRect(x: 20, y: 0, width: 380, height: 300))
    }

    @Test func followsVisibleFrameOfSecondaryScreen() {
        let visible = NSRect(x: -1920, y: 200, width: 1920, height: 1080)
        let frame = panelFrame(visibleFrame: visible, edge: .right, depthFraction: 0.5)
        #expect(frame == NSRect(x: -960, y: 200, width: 960, height: 1080))
    }

    @Test(arguments: [
        (General.PanelEdge.right, NSRect(x: 2000, y: 25, width: 900, height: 1100)),
        (.left, NSRect(x: -900, y: 25, width: 900, height: 1100)),
        (.top, NSRect(x: 0, y: 1125, width: 2000, height: 770)),
        (.bottom, NSRect(x: 0, y: -745, width: 2000, height: 770)),
    ])
    func slideStartsJustOutsideTheVisibleFrameOnTheEdge(edge: General.PanelEdge, expected: NSRect) {
        let visible = NSRect(x: 0, y: 25, width: 2000, height: 1100)
        let shown = panelFrame(visibleFrame: visible, edge: edge, depthFraction: edge.isVertical ? 0.7 : 0.45)
        #expect(offscreenFrame(shownFrame: shown, visibleFrame: visible, edge: edge) == expected)
    }

    @Test(arguments: [
        (General.PanelEdge.right, NSPoint(x: 1200, y: 500), 0.4),
        (.left, NSPoint(x: 1000, y: 500), 0.5),
        (.top, NSPoint(x: 300, y: 355), 0.7),
        (.bottom, NSPoint(x: 300, y: 575), 0.5),
    ])
    func draggingTheInnerBorderGivesTheDepthFraction(edge: General.PanelEdge, pointer: NSPoint, expected: Double) {
        let visible = NSRect(x: 0, y: 25, width: 2000, height: 1100)
        #expect(depthFraction(innerBorderAt: pointer, visibleFrame: visible, edge: edge) == expected)
    }

    @Test func draggedFractionIsClampedTo480PointsAnd95Percent() {
        let visible = NSRect(x: 0, y: 0, width: 2000, height: 1000)
        #expect(depthFraction(innerBorderAt: NSPoint(x: 1900, y: 0), visibleFrame: visible, edge: .right) == 0.24)
        #expect(depthFraction(innerBorderAt: NSPoint(x: 10, y: 0), visibleFrame: visible, edge: .right) == 0.95)
    }
}
