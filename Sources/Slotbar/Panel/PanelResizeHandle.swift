import AppKit

/// 6 pt strip on the Panel's inner border with the resize cursor; reports drags in screen coordinates (SPEC 4.3).
final class PanelResizeHandle: NSView {
    private static let thickness: CGFloat = 6

    var onDrag: ((_ pointer: NSPoint, _ ended: Bool) -> Void)?
    private var cursor = NSCursor.resizeLeftRight
    private var isDragging = false
    private var isInside = false

    /// Positions the strip on the side facing the screen centre for a Panel of `size` on `edge`.
    func place(on edge: General.PanelEdge, in size: NSSize) {
        let t = Self.thickness
        switch edge {
        case .right: frame = NSRect(x: 0, y: 0, width: t, height: size.height)
        case .left: frame = NSRect(x: size.width - t, y: 0, width: t, height: size.height)
        case .top: frame = NSRect(x: 0, y: 0, width: size.width, height: t)
        case .bottom: frame = NSRect(x: 0, y: size.height - t, width: size.width, height: t)
        }
        autoresizingMask = switch edge {
        case .right: [.height, .maxXMargin]
        case .left: [.height, .minXMargin]
        case .top: [.width, .maxYMargin]
        case .bottom: [.width, .minYMargin]
        }
        cursor = edge.isVertical ? .resizeUpDown : .resizeLeftRight
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        isInside = true
        cursor.set()
    }

    override func mouseExited(with event: NSEvent) {
        isInside = false
        if !isDragging { NSCursor.arrow.set() }
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        cursor.set()
    }

    override func mouseDragged(with event: NSEvent) {
        cursor.set()
        onDrag?(NSEvent.mouseLocation, false)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        onDrag?(NSEvent.mouseLocation, true)
        if !isInside { NSCursor.arrow.set() }
    }
}
