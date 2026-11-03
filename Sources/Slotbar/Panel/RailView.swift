import AppKit

/// Strip on the Panel's outer side: one icon per Slot, then the gear (SPEC 4.4).
@MainActor
final class RailView: NSView {
    static let thickness: CGFloat = 44

    var onSelect: ((UUID) -> Void)?
    var onAction: ((UUID, SlotAction) -> Void)?
    /// The right-click "Notifications" check item (a Settings edit, SPEC 4.4).
    var onToggleNotifications: ((UUID) -> Void)?
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
            let menu = Menus.slotMenu(notifications: item.notifications)
            for menuItem in menu.items {
                menuItem.target = self
                menuItem.tag = index
            }
            button.menu = menu
            button.layer?.backgroundColor = item.isActive
                ? NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor : nil
            if let badge = item.badge { addCapsule(badge, to: button) }
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

    /// Small filled capsule over the icon's top trailing corner (SPEC 8.4).
    private func addCapsule(_ text: String, to button: NSButton) {
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedDigitSystemFont(ofSize: 9, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.systemRed.cgColor
        label.layer?.cornerRadius = 6
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 12),
            label.widthAnchor.constraint(equalToConstant: max(12, label.intrinsicContentSize.width + 6)),
            label.topAnchor.constraint(equalTo: button.topAnchor),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor),
        ])
    }

    @objc private func iconClicked(_ sender: NSButton) {
        onSelect?(items[sender.tag].slotId)
    }

    @objc func goHome(_ sender: NSMenuItem) { send(.goHome, sender) }
    @objc func openInBrowser(_ sender: NSMenuItem) { send(.openInBrowser, sender) }
    @objc func reload(_ sender: NSMenuItem) { send(.reload, sender) }
    @objc func toggleNotifications(_ sender: NSMenuItem) {
        if let id = slotId(of: sender) { onToggleNotifications?(id) }
    }

    private func send(_ action: SlotAction, _ sender: NSMenuItem) {
        if let id = slotId(of: sender) { onAction?(id, action) }
    }

    private func slotId(of sender: NSMenuItem) -> UUID? {
        items.indices.contains(sender.tag) ? items[sender.tag].slotId : nil
    }
}
