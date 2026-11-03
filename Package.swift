// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slotbar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Slotbar",
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
