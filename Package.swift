// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slotbar",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.9.4"),
    ],
    targets: [
        .executableTarget(
            name: "Slotbar",
            dependencies: ["KeyboardShortcuts"],
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
