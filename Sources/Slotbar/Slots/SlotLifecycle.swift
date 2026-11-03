import Foundation

/// Reopen URL (SPEC 6.2): the last main-frame URL while it is on the Home host, else the starting URL.
func reopenURL(lastURL: URL?, slot: Slot) -> URL {
    guard let lastURL, lastURL.host()?.lowercased() == NavigationRouter.homeHost(slot) else { return slot.url }
    return lastURL
}

/// A Slot in the crash placeholder contributes its last Unread state as "count unknown" (SPEC 6.4).
func crashPlaceholderUnread(last: UnreadState) -> UnreadState {
    last == .none ? .none : .unknown
}

/// One Slot's lifecycle state and grace timer (SPEC 6.1, 6.2). Times are passed in; the owner runs the real timer.
struct SlotLifecycle {
    static let grace: TimeInterval = 5 * 60
    static let crashCap = 3
    static let crashWindow: TimeInterval = 10 * 60

    enum State: Equatable { case unloaded, loaded, crashPlaceholder }

    /// What to do after the Slot's page process terminated (SPEC 6.4).
    enum CrashResponse: Equatable {
        /// Close its Child windows and reload at the reopen URL.
        case reload
        /// Release the webview; it reloads on open.
        case unload
        /// Release the webview and show the crash placeholder.
        case placeholder
    }

    private(set) var state: State = .unloaded
    private(set) var keepAlive: Bool
    /// Its webview is in the Panel and the Panel is on screen.
    private(set) var isShown = false
    /// Open Child windows, minimized included; any counts as shown.
    private(set) var childWindowCount = 0
    /// When the running grace timer fires; nil when none runs.
    private(set) var graceDeadline: Date?
    /// Terminations within the last `crashWindow`.
    private var crashes: [Date] = []

    init(keepAlive: Bool) {
        self.keepAlive = keepAlive
    }

    /// The webview was created. Leaving the crash placeholder (an explicit load) resets the crash counter.
    mutating func loaded(at now: Date) {
        if state == .crashPlaceholder { crashes = [] }
        state = .loaded
        updateGrace(at: now)
    }

    mutating func setShown(_ shown: Bool, at now: Date) {
        isShown = shown
        updateGrace(at: now)
    }

    mutating func setChildWindowCount(_ count: Int, at now: Date) {
        childWindowCount = count
        updateGrace(at: now)
    }

    /// Keep-alive toggled in Settings. True when the Slot must load now (turned on while Unloaded).
    mutating func setKeepAlive(_ on: Bool, at now: Date) -> Bool {
        keepAlive = on
        updateGrace(at: now)
        return on && state == .unloaded
    }

    /// True when the grace period is over: unload the Slot.
    mutating func expireGrace(at now: Date) -> Bool {
        guard let graceDeadline, now >= graceDeadline else { return false }
        unloaded()
        return true
    }

    /// Memory pressure (SPEC 6.2): true when the Slot is in its grace period and must unload at once.
    mutating func memoryPressure() -> Bool {
        guard graceDeadline != nil else { return false }
        unloaded()
        return true
    }

    /// The Slot's own page process terminated; every termination counts toward the cap.
    mutating func crashed(at now: Date) -> CrashResponse {
        crashes = crashes.filter { now.timeIntervalSince($0) < Self.crashWindow } + [now]
        if crashes.count >= Self.crashCap {
            state = .crashPlaceholder
            graceDeadline = nil
            return .placeholder
        }
        if keepAlive || isShown || childWindowCount > 0 { return .reload }
        unloaded()
        return .unload
    }

    /// The webview was released.
    mutating func unloaded() {
        state = .unloaded
        graceDeadline = nil
    }

    /// A loaded, hidden, non-keep-alive Slot runs the timer; becoming hidden again keeps the running one.
    private mutating func updateGrace(at now: Date) {
        if state == .loaded, !keepAlive, !isShown, childWindowCount == 0 {
            if graceDeadline == nil { graceDeadline = now.addingTimeInterval(Self.grace) }
        } else {
            graceDeadline = nil
        }
    }
}
