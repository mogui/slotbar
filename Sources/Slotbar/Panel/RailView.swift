import AppKit

/// Strip on the Panel's outer side: one icon per Slot, then the gear (SPEC 4.4).
@MainActor
final class RailView: NSView {
    static let thickness: CGFloat = 44

    var onSelect: ((UUID) -> Void)?
    private let stack = NSStackView()
    private var items: [RailItem] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// `icon` returns a Slot's cached favicon; Slots without one show the globe tinted with the Profile color.
    func update(items: [RailItem], icon: (UUID) -> NSImage?) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.enumerated() {
            let button: NSButton
            if let favicon = icon(item.slotId) {
                button = faviconButton(favicon, color: item.color.nsColor)
            } else {
                button = iconButton(symbol: "globe", tint: item.color.nsColor)
            }
            button.tag = index
            button.target = self
            button.action = #selector(iconClicked(_:))
            button.toolTip = item.tooltip
            button.wantsLayer = true
            button.layer?.cornerRadius = 7
            button.layer?.backgroundColor = item.isActive
                ? NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor : nil
            stack.addArrangedSubview(button)
        }
        let gear = iconButton(symbol: "gearshape", tint: .secondaryLabelColor)
        gear.action = #selector(AppDelegate.showSettings(_:))
        gear.toolTip = "Settings"
        stack.addArrangedSubview(gear)
    }

    private func iconButton(symbol: String, tint: NSColor) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 18, weight: .regular))!
        let button = NSButton(image: image, target: nil, action: nil)
        button.isBordered = false
        button.contentTintColor = tint
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34),
        ])
        return button
    }

    /// The favicon plus a Profile-color dot in the bottom-right corner (SPEC 4.4).
    private func faviconButton(_ favicon: NSImage, color: NSColor) -> NSButton {
        let image = favicon.copy() as! NSImage
        image.size = NSSize(width: 20, height: 20)
        let button = NSButton(image: image, target: nil, action: nil)
        button.isBordered = false
        button.imageScaling = .scaleProportionallyDown
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34),
        ])
        let dot = NSView(frame: NSRect(x: 24, y: 24, width: 7, height: 7))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = color.cgColor
        dot.layer?.cornerRadius = 3.5
        dot.layer?.borderWidth = 1
        dot.layer?.borderColor = NSColor.windowBackgroundColor.cgColor
        button.addSubview(dot)
        return button
    }

    @objc private func iconClicked(_ sender: NSButton) {
        onSelect?(items[sender.tag].slotId)
    }
}
