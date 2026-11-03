import WebKit

/// One SlotController per Slot, in list order, reused by id across Settings changes.
@MainActor
final class SlotRegistry {
    private(set) var controllers: [SlotController] = []

    var slots: [Slot] { controllers.map(\.slot) }

    func controller(for id: UUID) -> SlotController? {
        controllers.controller(for: id)
    }

    /// The controller whose Slot webview or Child window holds `webView`.
    func controller(owning webView: WKWebView) -> SlotController? {
        controllers.first { $0.owns(webView) }
    }

    /// Closes the controllers of removed Slots, updates the kept ones, builds new ones with `make`,
    /// then gives every controller the Slot list and its Profile's name.
    func apply(_ settings: Settings, make: (Slot) -> SlotController) {
        let remaining = Set(settings.slots.map(\.id))
        for controller in controllers where !remaining.contains(controller.slot.id) {
            controller.close()
        }
        controllers = settings.slots.map { slot in
            guard let existing = controllers.controller(for: slot.id) else { return make(slot) }
            existing.slot = slot
            return existing
        }
        for controller in controllers {
            controller.slots = settings.slots
            controller.childWindows.profileName = settings.profile(for: controller.slot)?.name ?? ""
        }
    }
}

extension [SlotController] {
    @MainActor
    func controller(for id: UUID) -> SlotController? {
        first { $0.slot.id == id }
    }
}
