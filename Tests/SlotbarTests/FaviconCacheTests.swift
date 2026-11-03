import AppKit
import Foundation
import Observation
import Testing
@testable import Slotbar

@MainActor
@Suite struct FaviconCacheTests {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("FaviconCacheTests-\(UUID().uuidString)")

    static func pngData(width: Int, height: Int) -> Data {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        return rep.representation(using: .png, properties: [:])!
    }

    func pixelSize(_ image: NSImage?) -> NSSize? {
        guard let rep = image?.representations.first else { return nil }
        return NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }

    @Test func storedIconIsScaledTo64PixelsAndCachedPerSlot() {
        let cache = FaviconCache(directory: directory)
        let slot = UUID()

        cache.store(imageData: Self.pngData(width: 16, height: 16), for: slot)

        #expect(pixelSize(cache.image(for: slot)) == NSSize(width: 64, height: 64))
        #expect(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("\(slot.uuidString).png").path))
        #expect(cache.image(for: UUID()) == nil)
    }

    @Test func iconSurvivesRelaunch() {
        let slot = UUID()
        FaviconCache(directory: directory).store(imageData: Self.pngData(width: 128, height: 128), for: slot)

        #expect(pixelSize(FaviconCache(directory: directory).image(for: slot)) == NSSize(width: 64, height: 64))
    }

    @Test func undecodableDataStoresNothing() {
        let cache = FaviconCache(directory: directory)
        let slot = UUID()

        cache.store(imageData: Data("<html>not found</html>".utf8), for: slot)

        #expect(cache.image(for: slot) == nil)
        #expect(!cache.hasIcon(for: slot))
    }

    @Test func removedIconFallsBackToNoIcon() {
        let cache = FaviconCache(directory: directory)
        let slot = UUID()
        cache.store(imageData: Self.pngData(width: 32, height: 32), for: slot)

        cache.remove(slot)

        #expect(cache.image(for: slot) == nil)
        #expect(FaviconCache(directory: directory).image(for: slot) == nil)
    }

    /// Settings > Slots reads icons through Observation, so a new fetch shows without another edit (SPEC 10).
    @Test func readersAreToldWhenAnIconIsStoredOrRemoved() {
        let cache = FaviconCache(directory: directory)
        let slot = UUID()
        final class Changes: @unchecked Sendable { var count = 0 }
        let changes = Changes()
        func track() {
            withObservationTracking { _ = cache.image(for: slot) } onChange: { changes.count += 1 }
        }

        track()
        cache.store(imageData: Self.pngData(width: 16, height: 16), for: slot)
        #expect(changes.count == 1)

        track()
        cache.remove(slot)
        #expect(changes.count == 2)
    }
}
