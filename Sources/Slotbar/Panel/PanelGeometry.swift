import AppKit

/// Frame of the Panel on the right edge of `visibleFrame` (SPEC 4.2, 4.3).
func panelFrame(visibleFrame: NSRect, depthFraction: CGFloat) -> NSRect {
    let width = min(max(visibleFrame.width * depthFraction, 480), visibleFrame.width * 0.95)
    return NSRect(x: visibleFrame.maxX - width, y: visibleFrame.minY, width: width, height: visibleFrame.height)
}
