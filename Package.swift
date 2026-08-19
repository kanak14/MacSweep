// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacSweep",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacSweep", targets: ["MacSweep"])
    ],
    targets: [
        .executableTarget(
            name: "MacSweep",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MacSweepTests",
            dependencies: ["MacSweep"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
