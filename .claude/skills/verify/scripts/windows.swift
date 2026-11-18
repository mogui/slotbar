// Prints the on-screen windows of one process: `id layer x y w h name`. Usage: swift windows.swift <pid>
import CoreGraphics
import Foundation

let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for window in list where window[kCGWindowOwnerPID as String] as? Int == pid {
    let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
    let fields: [Any] = [window[kCGWindowNumber as String] ?? 0, window[kCGWindowLayer as String] ?? 0,
                         Int(bounds["X"] ?? 0), Int(bounds["Y"] ?? 0), Int(bounds["Width"] ?? 0), Int(bounds["Height"] ?? 0),
                         window[kCGWindowName as String] ?? ""]
    print(fields.map { "\($0)" }.joined(separator: " "))
}
