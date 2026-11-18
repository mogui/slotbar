// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slotbar",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.9.4"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "Slotbar",
            dependencies: ["KeyboardShortcuts", "SwiftTerm"],
            path: "Sources/Slotbar",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SlotbarTests",
            dependencies: ["Slotbar"],
            path: "Tests/SlotbarTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
