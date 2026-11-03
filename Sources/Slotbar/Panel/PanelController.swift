import AppKit

private let log = Log.logger("Panel")

/// Shows and hides the Panel on the right edge of the screen under the pointer.
@MainActor
final class PanelController {
    private let window = PanelWindow()

    init() {
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = content
    }

    /// Hidden: show and make key. Shown but not key: make key. Key: hide (SPEC 4.5).
    func toggle() {
        if !window.isVisible {
            show()
        } else if !window.isKeyWindow {
            window.makeKey()
        } else {
            hide()
        }
    }

    func show() {
        let pointer = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) ?? NSScreen.main else {
            log.error("No screen to show the Panel on")
            return
        }
        window.setFrame(panelFrame(visibleFrame: screen.visibleFrame, depthFraction: 0.45), display: true)
        window.makeKeyAndOrderFront(nil)
        log.debug("Panel shown")
    }

    func hide() {
        window.orderOut(nil)
        log.debug("Panel hidden")
    }
}
