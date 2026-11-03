import AppKit

private let log = Log.logger("Panel")

/// Shows and hides the Panel on the right edge of the screen under the pointer; hosts the Rail and the active Slot.
@MainActor
final class PanelController {
    private let window = PanelWindow()
    private let rail = RailView()
    private let slotArea = NSView()
    private let emptyState = PanelController.makeEmptyState()
    private var settings: Settings?
    private var controllers: [SlotController] = []
    /// Last active Slot, in memory only (SPEC 4.5).
    private var activeSlot: UUID?

    init() {
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        content.autoresizesSubviews = true
        window.contentView = content

        rail.autoresizingMask = [.minXMargin, .height]
        slotArea.autoresizingMask = [.width, .height]
        content.addSubview(slotArea)
        content.addSubview(rail)
        rail.onSelect = { [weak self] id in self?.activate(id) }
    }

    /// Replaces the Slot list shown in the Rail; keeps the active Slot when it still exists.
    func update(settings: Settings, controllers: [SlotController]) {
        self.settings = settings
        self.controllers = controllers
        if window.isVisible {
            activate(slotToShow(slots: settings.slots, lastActive: activeSlot))
        } else {
            refreshRail()
        }
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
        layoutContent()
        activate(slotToShow(slots: settings?.slots ?? [], lastActive: activeSlot))
        window.makeKeyAndOrderFront(nil)
        log.debug("Panel shown")
    }

    func hide() {
        window.orderOut(nil)
        log.debug("Panel hidden")
    }

    /// Makes a Slot active, loading it if needed; `nil` shows the empty state.
    private func activate(_ id: UUID?) {
        activeSlot = id
        slotArea.subviews.forEach { $0.removeFromSuperview() }
        let view: NSView
        if let id, let controller = controllers.first(where: { $0.slot.id == id }) {
            view = controller.load()
        } else {
            view = emptyState
        }
        view.frame = slotArea.bounds
        view.autoresizingMask = [.width, .height]
        slotArea.addSubview(view)
        if view !== emptyState { window.makeFirstResponder(view) }
        refreshRail()
    }

    /// Redraws the Rail, including each loaded Slot's badge.
    func refreshRail() {
        guard let settings else { return }
        var unread: [UUID: UnreadState] = [:]
        for controller in controllers {
            if let state = controller.unread { unread[controller.slot.id] = state }
        }
        rail.update(items: railItems(settings: settings, activeSlot: activeSlot, unread: unread))
    }

    /// Right edge only for now: the Rail sits on the outer (right) side.
    private func layoutContent() {
        guard let bounds = window.contentView?.bounds else { return }
        rail.frame = NSRect(x: bounds.maxX - RailView.thickness, y: 0, width: RailView.thickness, height: bounds.height)
        slotArea.frame = NSRect(x: 0, y: 0, width: bounds.width - RailView.thickness, height: bounds.height)
    }

    /// "No Slots" with an "Open Settings" button (SPEC 4.4).
    private static func makeEmptyState() -> NSView {
        let label = NSTextField(labelWithString: "No Slots")
        label.font = .systemFont(ofSize: NSFont.systemFontSize + 4, weight: .semibold)
        label.textColor = .secondaryLabelColor
        let button = NSButton(title: "Open Settings", target: nil, action: #selector(AppDelegate.showSettings(_:)))
        let stack = NSStackView(views: [label, button])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let view = NSView()
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }
}
