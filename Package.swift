// swift-tools-version: 5.6
// (be sure to update the .swift-version file when this Swift version changes)

import PackageDescription

let package = Package(
    name: "MarkersExtractor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MarkersExtractor",
            type: .static,
            targets: ["MarkersExtractor"]
        ),
        .executable(
            name: "markers-extractor-cli",
            targets: ["markers-extractor-cli"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.6"),
        .package(url: "https://github.com/orchetect/TextFileKit.git", from: "0.1.6"),
        .package(url: "https://github.com/orchetect/TimecodeKit.git", from: "2.0.8"),
        .package(url: "https://github.com/orchetect/DAWFileKit.git", from: "0.4.1")
    ],
    targets: [
        .target(
            name: "MarkersExtractor",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "TextFileKit", package: "TextFileKit"),
                .product(name: "TimecodeKit", package: "TimecodeKit"),
                .product(name: "DAWFileKit", package: "DAWFileKit")
            ]
        ),
        .testTarget(
            name: "MarkersExtractorTests",
            dependencies: ["MarkersExtractor"],
            resources: [.copy("TestResource/Media Files")]
        ),
        .executableTarget(
            name: "markers-extractor-cli",
            dependencies: [
                "MarkersExtractor",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
