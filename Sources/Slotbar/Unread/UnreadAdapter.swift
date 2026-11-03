import Foundation

/// Any host other than Gmail and Chat: a leading `(N)` in the page title, else nothing (SPEC 8.4).
func titleUnread(_ title: String) -> UnreadState {
    guard let match = title.prefixMatch(of: /\((\d+)\)/), let n = Int(match.1), n > 0 else { return .none }
    return .count(n)
}

/// `chat.google.com`: favicon dot only. An unrecognized icon is a failing source and keeps the last state.
func chatUnread(faviconHref: String?, last: UnreadState) -> UnreadState {
    guard let href = faviconHref else { return last }
    if href.contains("_no_dot_") { return .none }
    if href.contains("_dot_") { return .unknown }
    return last
}

/// What `unread-gmail.js` reports: the Inbox DOM count, the Atom feed count, or both failing.
enum GmailSignal: Equatable {
    case dom(Int)
    case atom(Int)
    case failed

    enum Source: String, Equatable { case dom, atom, failed }

    var source: Source {
        switch self {
        case .dom: .dom
        case .atom: .atom
        case .failed: .failed
        }
    }
}

/// `mail.google.com` Unread state. With both sources down, unread seen last becomes "count unknown".
struct GmailUnread {
    private(set) var state: UnreadState = .none
    private var source: GmailSignal.Source?

    /// Returns the new source when it differs from the previous signal's, for logging.
    @discardableResult
    mutating func apply(_ signal: GmailSignal) -> GmailSignal.Source? {
        switch signal {
        case .dom(let n), .atom(let n): state = n > 0 ? .count(n) : .none
        case .failed: if state != .none { state = .unknown }
        }
        let previous = source
        source = signal.source
        return previous == signal.source ? nil : signal.source
    }
}
