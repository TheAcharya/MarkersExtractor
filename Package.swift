// swift-tools-version: 5.6
// (be sure to update the .swift-version file when this Swift version changes)

import PackageDescription

let package = Package(
    name: "MarkersExtractor",
    platforms: [
        .macOS(.v10_15)
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/dehesa/CodableCSV.git", from: "0.6.7"),
        .package(url: "https://github.com/TheAcharya/pipeline-neo.git", from: "0.1.1"),
        .package(url: "https://github.com/orchetect/TimecodeKit.git", from: "2.0.3"),
        .package(url: "https://github.com/orchetect/DAWFileKit.git", from: "0.2.8")
    ],
    targets: [
        .target(
            name: "MarkersExtractor",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "CodableCSV", package: "CodableCSV"),
                .product(name: "Pipeline", package: "pipeline-neo"),
                .product(name: "TimecodeKit", package: "TimecodeKit"),
                "DAWFileKit"
            ]
        ),
        .testTarget(
            name: "MarkersExtractorTests",
            dependencies: ["MarkersExtractor"]
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
