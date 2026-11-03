import AppKit

/// A Profile's `#RRGGBB` color; anything unparsable shows as palette graphite (SPEC 3.1, 10.2).
struct ProfileColor: Equatable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: String) {
        let digits = hex.dropFirst()
        guard hex.first == "#", digits.count == 6, digits.allSatisfy(\.isHexDigit),
              let value = UInt32(digits, radix: 16) else {
            self.init(red: 0x8E, green: 0x8E, blue: 0x93)
            return
        }
        self.init(red: UInt8(value >> 16 & 0xFF), green: UInt8(value >> 8 & 0xFF), blue: UInt8(value & 0xFF))
    }

    var nsColor: NSColor {
        NSColor(srgbRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
}
