import AppKit

/// Strip on the Panel's outer side: one icon per Slot, then the gear (SPEC 4.4).
@MainActor
final class RailView: NSView {
    static let thickness: CGFloat = 44

    var onSelect: ((UUID) -> Void)?
    private let stack = NSStackView()
    private var items: [RailItem] = []
    private lazy var verticalConstraints = [
        stack.topAnchor.constraint(equalTo: topAnchor),
        stack.leadingAnchor.constraint(equalTo: leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: trailingAnchor),
    ]
    private lazy var horizontalConstraints = [
        stack.leadingAnchor.constraint(equalTo: leadingAnchor),
        stack.topAnchor.constraint(equalTo: topAnchor),
        stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]

    /// Vertical strip for left/right Panels, horizontal for top/bottom (SPEC 4.4).
    var isHorizontal = false {
        didSet {
            guard isHorizontal != oldValue else { return }
            NSLayoutConstraint.deactivate(isHorizontal ? verticalConstraints : horizontalConstraints)
            NSLayoutConstraint.activate(isHorizontal ? horizontalConstraints : verticalConstraints)
            stack.orientation = isHorizontal ? .horizontal : .vertical
            stack.alignment = isHorizontal ? .centerY : .centerX
            stack.edgeInsets = isHorizontal
                ? NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
                : NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate(verticalConstraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(items: [RailItem]) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.enumerated() {
            let button = iconButton(symbol: "globe", tint: item.color.nsColor)
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

    @objc private func iconClicked(_ sender: NSButton) {
        onSelect?(items[sender.tag].slotId)
    }
}
