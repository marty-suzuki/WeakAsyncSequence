// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WeakAsyncSequence",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "WeakAsyncSequence",
            targets: ["WeakAsyncSequence"]),
    ],
    targets: [
        .target(
            name: "WeakAsyncSequence"),
        .testTarget(
            name: "WeakAsyncSequenceTests",
            dependencies: ["WeakAsyncSequence"]
        ),
    ]
)
