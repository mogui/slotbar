import AppKit

/// Frame of the shown Panel: full edge length of `visibleFrame`, depth clamped to [480 pt, 95%] (SPEC 4.2, 4.3).
func panelFrame(visibleFrame: NSRect, edge: General.PanelEdge, depthFraction: CGFloat) -> NSRect {
    let v = visibleFrame
    let dimension = edge.isVertical ? v.height : v.width
    let depth = min(max(dimension * depthFraction, 480), dimension * 0.95)
    switch edge {
    case .left: return NSRect(x: v.minX, y: v.minY, width: depth, height: v.height)
    case .right: return NSRect(x: v.maxX - depth, y: v.minY, width: depth, height: v.height)
    case .top: return NSRect(x: v.minX, y: v.maxY - depth, width: v.width, height: depth)
    case .bottom: return NSRect(x: v.minX, y: v.minY, width: v.width, height: depth)
    }
}

/// Slide start (show) and end (hide) frame: `shownFrame` moved just outside `visibleFrame` on the edge (SPEC 4.5).
func offscreenFrame(shownFrame: NSRect, visibleFrame: NSRect, edge: General.PanelEdge) -> NSRect {
    var frame = shownFrame
    switch edge {
    case .left: frame.origin.x = visibleFrame.minX - frame.width
    case .right: frame.origin.x = visibleFrame.maxX
    case .top: frame.origin.y = visibleFrame.maxY
    case .bottom: frame.origin.y = visibleFrame.minY - frame.height
    }
    return frame
}

/// Depth fraction for the Panel's inner border dragged to `pointer`, clamped like `panelFrame` (SPEC 4.3).
func depthFraction(innerBorderAt pointer: NSPoint, visibleFrame: NSRect, edge: General.PanelEdge) -> Double {
    let v = visibleFrame
    let dimension = edge.isVertical ? v.height : v.width
    let depth: CGFloat
    switch edge {
    case .left: depth = pointer.x - v.minX
    case .right: depth = v.maxX - pointer.x
    case .top: depth = v.maxY - pointer.y
    case .bottom: depth = pointer.y - v.minY
    }
    return min(max(depth, 480), dimension * 0.95) / dimension
}

extension General.PanelEdge {
    /// Top and bottom Panels take their depth from the screen height (`panelDepth.vertical`).
    var isVertical: Bool { self == .top || self == .bottom }
}
