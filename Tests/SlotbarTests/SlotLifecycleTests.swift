import Foundation
import Testing
@testable import Slotbar

@Suite struct SlotLifecycleTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    func at(minutes: Double) -> Date { start.addingTimeInterval(minutes * 60) }

    /// A non-keep-alive Slot loaded and shown in the Panel at `start`.
    func shownSlot() -> SlotLifecycle {
        var lifecycle = SlotLifecycle(keepAlive: false)
        lifecycle.setShown(true, at: start)
        lifecycle.loaded(at: start)
        return lifecycle
    }

    @Test func hiddenSlotUnloadsAfterFiveMinutes() {
        var lifecycle = shownSlot()
        lifecycle.setShown(false, at: start)
        let early = lifecycle.expireGrace(at: at(minutes: 4.9))
        let due = lifecycle.expireGrace(at: at(minutes: 5))
        #expect(!early && due)
        #expect(lifecycle.state == .unloaded)
    }

    @Test func showingAgainCancelsTheGraceTimer() {
        var lifecycle = shownSlot()
        lifecycle.setShown(false, at: start)
        lifecycle.setShown(true, at: at(minutes: 2))
        let unload = lifecycle.expireGrace(at: at(minutes: 10))
        #expect(!unload && lifecycle.state == .loaded)
    }

    @Test func hidingAgainRestartsAFullGracePeriod() {
        var lifecycle = shownSlot()
        lifecycle.setShown(false, at: start)
        lifecycle.setShown(true, at: at(minutes: 2))
        lifecycle.setShown(false, at: at(minutes: 3))
        let early = lifecycle.expireGrace(at: at(minutes: 7.9))
        let due = lifecycle.expireGrace(at: at(minutes: 8))
        #expect(!early && due)
    }

    @Test func keptAliveSlotNeverUnloads() {
        var lifecycle = SlotLifecycle(keepAlive: true)
        lifecycle.loaded(at: start)
        lifecycle.setShown(true, at: start)
        lifecycle.setShown(false, at: start)
        let unload = lifecycle.expireGrace(at: at(minutes: 60))
        #expect(!unload && lifecycle.graceDeadline == nil)
    }

    @Test func slotLoadedInTheBackgroundRunsTheGraceTimer() {
        var lifecycle = SlotLifecycle(keepAlive: false)
        lifecycle.loaded(at: start)
        #expect(lifecycle.graceDeadline == at(minutes: 5))
    }

    @Test func openChildWindowCountsAsShown() {
        var lifecycle = shownSlot()
        lifecycle.setChildWindowCount(1, at: start)
        lifecycle.setShown(false, at: start)
        let unload = lifecycle.expireGrace(at: at(minutes: 60))
        #expect(!unload && lifecycle.graceDeadline == nil)
    }

    @Test func closingTheLastChildWindowStartsTheFullGraceTimer() {
        var lifecycle = shownSlot()
        lifecycle.setChildWindowCount(2, at: start)
        lifecycle.setShown(false, at: start)
        lifecycle.setChildWindowCount(1, at: at(minutes: 10))
        lifecycle.setChildWindowCount(0, at: at(minutes: 20))
        #expect(lifecycle.graceDeadline == at(minutes: 25))
    }

    @Test func keepAliveOffStartsTheGraceTimerWhenHidden() {
        var lifecycle = SlotLifecycle(keepAlive: true)
        lifecycle.loaded(at: start)
        let load = lifecycle.setKeepAlive(false, at: at(minutes: 1))
        #expect(!load && lifecycle.graceDeadline == at(minutes: 6))
    }

    @Test func keepAliveOnLoadsAnUnloadedSlotAtOnce() {
        var lifecycle = SlotLifecycle(keepAlive: false)
        let load = lifecycle.setKeepAlive(true, at: start)
        #expect(load)
    }

    @Test func keepAliveOnCancelsTheGraceTimer() {
        var lifecycle = SlotLifecycle(keepAlive: false)
        lifecycle.loaded(at: start)
        let load = lifecycle.setKeepAlive(true, at: start)
        #expect(!load && lifecycle.graceDeadline == nil)
    }

    @Test func memoryPressureUnloadsASlotInItsGracePeriod() {
        var lifecycle = shownSlot()
        lifecycle.setShown(false, at: start)
        let unload = lifecycle.memoryPressure()
        #expect(unload && lifecycle.state == .unloaded)
    }

    @Test func memoryPressureSkipsHiddenSlotsWithChildWindows() {
        var lifecycle = shownSlot()
        lifecycle.setChildWindowCount(1, at: start)
        lifecycle.setShown(false, at: start)
        let unload = lifecycle.memoryPressure()
        #expect(!unload && lifecycle.state == .loaded)
    }

    @Test func memoryPressureSkipsShownSlots() {
        var lifecycle = shownSlot()
        let unload = lifecycle.memoryPressure()
        #expect(!unload)
    }

    @Test func memoryPressureSkipsKeptAliveSlots() {
        var lifecycle = SlotLifecycle(keepAlive: true)
        lifecycle.loaded(at: start)
        let unload = lifecycle.memoryPressure()
        #expect(!unload)
    }

    @Test func shownSlotReloadsAfterACrash() {
        var lifecycle = shownSlot()
        let response = lifecycle.crashed(at: start)
        #expect(response == .reload)
    }

    @Test func keptAliveHiddenSlotReloadsAfterACrash() {
        var lifecycle = SlotLifecycle(keepAlive: true)
        lifecycle.loaded(at: start)
        let response = lifecycle.crashed(at: start)
        #expect(response == .reload)
    }

    @Test func hiddenSlotWithAChildWindowReloadsAfterACrash() {
        var lifecycle = shownSlot()
        lifecycle.setChildWindowCount(1, at: start)
        lifecycle.setShown(false, at: start)
        let response = lifecycle.crashed(at: start)
        #expect(response == .reload)
    }

    @Test func hiddenSlotIsMarkedUnloadedAfterACrash() {
        var lifecycle = shownSlot()
        lifecycle.setShown(false, at: start)
        let response = lifecycle.crashed(at: at(minutes: 1))
        #expect(response == .unload && lifecycle.state == .unloaded && lifecycle.graceDeadline == nil)
    }

    @Test func thirdCrashWithinTenMinutesShowsThePlaceholder() {
        var lifecycle = shownSlot()
        _ = lifecycle.crashed(at: start)
        _ = lifecycle.crashed(at: at(minutes: 4))
        let response = lifecycle.crashed(at: at(minutes: 9.9))
        #expect(response == .placeholder && lifecycle.state == .crashPlaceholder)
    }

    @Test func crashesOlderThanTenMinutesDoNotCount() {
        var lifecycle = shownSlot()
        _ = lifecycle.crashed(at: start)
        _ = lifecycle.crashed(at: at(minutes: 4))
        let response = lifecycle.crashed(at: at(minutes: 10))
        #expect(response == .reload)
    }

    @Test func crashesOfAHiddenSlotCountTowardTheCap() {
        var lifecycle = shownSlot()
        _ = lifecycle.crashed(at: start)
        _ = lifecycle.crashed(at: at(minutes: 1))
        lifecycle.setShown(false, at: at(minutes: 2))
        let response = lifecycle.crashed(at: at(minutes: 3))
        #expect(response == .placeholder)
    }

    @Test func placeholderIsExemptFromGraceAndMemoryPressure() {
        var lifecycle = shownSlot()
        for minute in 0..<3 { _ = lifecycle.crashed(at: at(minutes: Double(minute))) }
        lifecycle.setShown(false, at: at(minutes: 3))
        let unload = lifecycle.memoryPressure()
        #expect(!unload && lifecycle.graceDeadline == nil && lifecycle.state == .crashPlaceholder)
    }

    @Test func loadingFromThePlaceholderResetsTheCrashCounter() {
        var lifecycle = shownSlot()
        for minute in 0..<3 { _ = lifecycle.crashed(at: at(minutes: Double(minute))) }
        lifecycle.loaded(at: at(minutes: 3))
        #expect(lifecycle.state == .loaded)
        let response = lifecycle.crashed(at: at(minutes: 4))
        #expect(response == .reload)
    }
}
