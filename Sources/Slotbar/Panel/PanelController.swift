import AppKit

private let log = Log.logger("Panel")

/// Shows, hides, slides and resizes the Panel on the configured edge of the screen under the pointer (SPEC 4.2, 4.3, 4.5).
@MainActor
final class PanelController: NSObject {
    private let window = PanelWindow()
    private let settingsStore: SettingsStore
    private let resizeHandle = PanelResizeHandle()
    private var policy = PanelToggle()
    /// Screen and edge fixed at show time; the Panel stays there until hidden.
    private var screen: NSScreen?
    private var edge: General.PanelEdge = .right
    private var previousApp: NSRunningApplication?
    /// Bumped by every show/hide so a superseded animation's completion does nothing.
    private var animationID = 0
    private var isShowing = false

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init()
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        content.addSubview(resizeHandle)
        window.contentView = content
        resizeHandle.onDrag = { [weak self] pointer, ended in self?.resizeDragged(to: pointer, ended: ended) }

        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: window)
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    /// True when the Panel (or, once they exist, one of its Child windows) is key.
    private var isKey: Bool { window.isKeyWindow }

    /// Global hotkey toggle (SPEC 4.5).
    func toggle() {
        perform(policy.toggle(isVisible: isShowing, isKey: isKey))
    }

    /// Status icon mouse-down: records visibility so the click never hides and re-shows.
    func statusMouseDown() {
        policy.statusMouseDown(isVisible: isShowing, isKey: isKey)
    }

    func statusMouseUp() {
        if let action = policy.statusMouseUp() { perform(action) }
    }

    private func perform(_ action: PanelToggle.Action) {
        switch action {
        case .show: show()
        case .makeKey: window.makeKey()
        case .hide: hide()
        }
    }

    func show() {
        let pointer = NSEvent.mouseLocation
        guard let target = NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) ?? NSScreen.main else {
            log.error("No screen to show the Panel on")
            return
        }
        if !isShowing {
            if let front = NSWorkspace.shared.frontmostApplication, front != .current { previousApp = front }
            screen = target
            edge = settingsStore.settings.general.panelEdge
        }
        isShowing = true
        guard let screen else { return }
        let visible = screen.visibleFrame
        let shown = panelFrame(visibleFrame: visible, edge: edge, depthFraction: storedFraction)
        resizeHandle.place(on: edge, in: shown.size)

        animationID += 1
        let id = animationID
        if !window.isVisible {
            if reduceMotion {
                window.alphaValue = 0
                window.setFrame(shown, display: false)
            } else {
                window.alphaValue = 1
                window.setFrame(offscreenFrame(shownFrame: shown, visibleFrame: visible, edge: edge), display: false)
            }
        }
        window.level = .popUpMenu
        window.makeKeyAndOrderFront(nil)
        animate(duration: reduceMotion ? 0.15 : 0.2, timing: .easeOut) { [window] in
            window.animator().setFrame(shown, display: true)
            window.animator().alphaValue = 1
        } completion: { [weak self] in
            guard let self, self.animationID == id else { return }
            self.window.level = .floating
            log.debug("Panel shown")
        }
    }

    func hide() {
        guard isShowing, let screen else { return }
        isShowing = false
        let visible = screen.visibleFrame
        animationID += 1
        let id = animationID
        window.level = .popUpMenu
        let fade = reduceMotion
        // Starts from the current frame, so a hide during the show slide reverses from where it is.
        let target = offscreenFrame(
            shownFrame: panelFrame(visibleFrame: visible, edge: edge, depthFraction: storedFraction),
            visibleFrame: visible, edge: edge)
        animate(duration: fade ? 0.15 : 0.2, timing: .easeIn) { [window] in
            if fade { window.animator().alphaValue = 0 } else { window.animator().setFrame(target, display: true) }
        } completion: { [weak self] in
            guard let self, self.animationID == id else { return }
            self.window.orderOut(nil)
            self.window.alphaValue = 1
            self.reactivatePreviousApp()
            log.debug("Panel hidden")
        }
    }

    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private var storedFraction: CGFloat {
        let depth = settingsStore.settings.general.panelDepth
        return edge.isVertical ? depth.vertical : depth.horizontal
    }

    private func animate(duration: TimeInterval, timing: CAMediaTimingFunctionName,
                         changes: () -> Void, completion: @escaping @MainActor () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: timing)
            changes()
        }, completionHandler: {
            MainActor.assumeIsolated { completion() }
        })
    }

    /// Gives focus back to the app that was frontmost at show, unless the user already moved to another app.
    private func reactivatePreviousApp() {
        guard let previousApp, !previousApp.isTerminated else { return }
        let front = NSWorkspace.shared.frontmostApplication
        if front == nil || front == .current || front == previousApp {
            previousApp.activate()
        }
        self.previousApp = nil
    }

    private func resizeDragged(to pointer: NSPoint, ended: Bool) {
        guard isShowing, let screen else { return }
        let visible = screen.visibleFrame
        let fraction = depthFraction(innerBorderAt: pointer, visibleFrame: visible, edge: edge)
        let frame = panelFrame(visibleFrame: visible, edge: edge, depthFraction: fraction)
        window.setFrame(frame, display: true)
        resizeHandle.place(on: edge, in: frame.size)
        guard ended else { return }
        let vertical = edge.isVertical
        settingsStore.update { settings in
            if vertical { settings.general.panelDepth.vertical = fraction } else { settings.general.panelDepth.horizontal = fraction }
        }
    }

    /// Auto-hide (SPEC 4.5): any key window in this app (Settings, sheets, open/save panels, JS dialogs,
    /// Child windows) is a Slotbar window. The new key window is known only after the resign completes.
    @objc private func windowDidResignKey(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.isShowing else { return }
                let enabled = self.settingsStore.settings.general.hideOnFocusLoss
                if self.policy.shouldAutoHide(enabled: enabled, newKeyWindowIsSlotbars: NSApp.keyWindow != nil) {
                    self.hide()
                }
            }
        }
    }

    /// Display change (SPEC 4.2): re-apply the collection behavior, hide if the Panel's screen is gone.
    @objc private func screensDidChange(_ notification: Notification) {
        window.collectionBehavior = PanelWindow.collectionBehavior
        guard isShowing, let screen else { return }
        let number = NSDeviceDescriptionKey("NSScreenNumber")
        let id = screen.deviceDescription[number] as? NSNumber
        if !NSScreen.screens.contains(where: { $0.deviceDescription[number] as? NSNumber == id }) {
            log.info("Panel screen disconnected; hiding")
            hide()
        }
    }
}
