import AppKit

/// `window.open` size when the page passes none (SPEC 4.7).
let defaultChildWindowSize = NSSize(width: 800, height: 700)

/// Child window frame (SPEC 4.7): `window.open` size (default 800x700) clamped to the visible frame,
/// centered in the largest part of the visible frame the Panel does not cover.
func childWindowFrame(width: CGFloat?, height: CGFloat?, visibleFrame v: NSRect, panelFrame: NSRect?) -> NSRect {
    let size = NSSize(width: min(width ?? defaultChildWindowSize.width, v.width),
                      height: min(height ?? defaultChildWindowSize.height, v.height))
    var area = v
    if let panel = panelFrame?.intersection(v), !panel.isEmpty {
        let parts = [
            NSRect(x: v.minX, y: v.minY, width: panel.minX - v.minX, height: v.height),
            NSRect(x: panel.maxX, y: v.minY, width: v.maxX - panel.maxX, height: v.height),
            NSRect(x: v.minX, y: v.minY, width: v.width, height: panel.minY - v.minY),
            NSRect(x: v.minX, y: panel.maxY, width: v.width, height: v.maxY - panel.maxY),
        ]
        area = parts.max { $0.width * $0.height < $1.width * $1.height } ?? v
    }
    let x = min(max(area.midX - size.width / 2, v.minX), v.maxX - size.width)
    let y = min(max(area.midY - size.height / 2, v.minY), v.maxY - size.height)
    return NSRect(x: x.rounded(.down), y: y.rounded(.down), width: size.width, height: size.height)
}

/// `<page title> - <Profile name>`; the Profile name alone while the page has no title (SPEC 4.7).
func childWindowTitle(pageTitle: String?, profileName: String) -> String {
    let title = pageTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return title.isEmpty ? profileName : "\(title) - \(profileName)"
}
