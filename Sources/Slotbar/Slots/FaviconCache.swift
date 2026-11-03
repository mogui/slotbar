import AppKit

private let log = Log.logger("Slots")

/// Rail icons as 64x64 px PNGs in `favicons/<slot-id>.png`, kept in memory once read (SPEC 3.2, 4.4).
@MainActor
final class FaviconCache {
    static let pixelSize = 64
    private let directory: URL
    private var images: [UUID: NSImage] = [:]

    init(directory: URL) {
        self.directory = directory
    }

    func image(for slotId: UUID) -> NSImage? {
        if let image = images[slotId] { return image }
        guard let image = NSImage(contentsOf: file(for: slotId)) else { return nil }
        images[slotId] = image
        return image
    }

    func hasIcon(for slotId: UUID) -> Bool {
        image(for: slotId) != nil
    }

    /// Decodes any image format NSImage reads (PNG, ICO, SVG...), scales it and writes the PNG; undecodable data is ignored.
    func store(imageData: Data, for slotId: UUID) {
        guard let source = NSImage(data: imageData), source.isValid,
              let png = Self.scaledPNG(source) else {
            log.debug("Favicon for Slot \(slotId, privacy: .public) is not an image")
            return
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try png.write(to: file(for: slotId), options: .atomic)
            images[slotId] = NSImage(data: png)
        } catch {
            log.error("Cannot write favicon: \(error.localizedDescription, privacy: .public)")
        }
    }

    func remove(_ slotId: UUID) {
        images[slotId] = nil
        try? FileManager.default.removeItem(at: file(for: slotId))
    }

    private func file(for slotId: UUID) -> URL {
        directory.appendingPathComponent("\(slotId.uuidString).png")
    }

    private static func scaledPNG(_ source: NSImage) -> Data? {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        rep.size = NSSize(width: pixelSize, height: pixelSize)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        source.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}
