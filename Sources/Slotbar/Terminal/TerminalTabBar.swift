import AppKit

/// One tab in the Terminal's tab bar.
struct TerminalTabItem: Equatable {
    var id: Int
    var title: String
    var isActive: Bool
}

/// The tab bar's items; empty (no bar) with a single tab, so the shell gets all the space.
/// `fallbackTitle` names a tab whose shell set no title.
func terminalTabBar(tabs: [TerminalSession.Tab], activeTab: Int,
                    fallbackTitle: (Int) -> String) -> [TerminalTabItem] {
    guard tabs.count > 1 else { return [] }
    return tabs.map {
        TerminalTabItem(id: $0.id, title: $0.title.isEmpty ? fallbackTitle($0.id) : $0.title,
                        isActive: $0.id == activeTab)
    }
}

/// The strip above the shell with one tab per Terminal tab (shown only with two or more).
/// Click selects, the hover "xmark" closes, a double-click on the empty part opens a tab.
@MainActor
final class TerminalTabBarView: NSView {
    static let height: CGFloat = 28
    private static let maxTabWidth: CGFloat = 200

    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onNewTab: (() -> Void)?
    private var cells: [TabCell] = []

    func update(items: [TerminalTabItem]) {
        while cells.count > items.count { cells.removeLast().removeFromSuperview() }
        while cells.count < items.count {
            let cell = TabCell()
            cell.onSelect = { [weak self] id in self?.onSelect?(id) }
            cell.onClose = { [weak self] id in self?.onClose?(id) }
            addSubview(cell)
            cells.append(cell)
        }
        zip(cells, items).forEach { $0.show($1) }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard !cells.isEmpty else { return }
        let width = min(Self.maxTabWidth, bounds.width / CGFloat(cells.count))
        for (i, cell) in cells.enumerated() {
            cell.frame = NSRect(x: CGFloat(i) * width, y: 0, width: width, height: bounds.height)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
    }

    /// Only the empty part reaches here; the tabs take their own clicks.
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 { onNewTab?() }
    }
}

@MainActor
private final class TabCell: NSView {
    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    private var item = TerminalTabItem(id: 0, title: "", isActive: false)
    private let label = NSTextField(labelWithString: "")
    private let close = NSButton()

    init() {
        super.init(frame: .zero)
        label.lineBreakMode = .byTruncatingTail
        label.alignment = .center
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.translatesAutoresizingMaskIntoConstraints = false
        close.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close tab")
        close.setAccessibilityLabel("Close tab")
        close.isBordered = false
        close.imageScaling = .scaleProportionallyDown
        close.target = self
        close.action = #selector(closeClicked)
        close.isHidden = true
        close.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        addSubview(close)
        NSLayoutConstraint.activate([
            close.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            close.centerYAnchor.constraint(equalTo: centerYAnchor),
            close.widthAnchor.constraint(equalToConstant: 14),
            close.heightAnchor.constraint(equalToConstant: 14),
            label.leadingAnchor.constraint(equalTo: close.trailingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(_ item: TerminalTabItem) {
        self.item = item
        label.stringValue = item.title
        label.textColor = item.isActive ? .labelColor : .secondaryLabelColor
        toolTip = item.title
        setAccessibilityLabel(item.title)
        setAccessibilitySelected(item.isActive)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if item.isActive {
            NSColor.controlBackgroundColor.setFill()
            bounds.fill()
        }
        NSColor.separatorColor.setFill()
        NSRect(x: bounds.maxX - 1, y: 4, width: 1, height: bounds.height - 8).fill()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    override func mouseEntered(with event: NSEvent) { close.isHidden = false }
    override func mouseExited(with event: NSEvent) { close.isHidden = true }
    override func mouseDown(with event: NSEvent) { onSelect?(item.id) }
    override func accessibilityPerformPress() -> Bool {
        onSelect?(item.id)
        return true
    }

    @objc private func closeClicked() { onClose?(item.id) }
}
