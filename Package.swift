// swift-tools-version: 6.0
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
            name: "markers-extractor",
            targets: ["MarkersExtractorCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.4"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.2.1"),
        .package(url: "https://github.com/TheAcharya/xlsxwriter.git", from: "1.0.3"),
        .package(url: "https://github.com/orchetect/TextFileKit.git", from: "0.2.1"),
        .package(url: "https://github.com/orchetect/TimecodeKit.git", from: "2.3.3"),
        .package(url: "https://github.com/orchetect/DAWFileKit.git", from: "0.5.3"),
        .package(url: "https://github.com/orchetect/OTCore.git", from: "1.7.7"),
        .package(url: "https://github.com/orchetect/swift-testing-extensions.git", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "MarkersExtractor",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "xlsxwriter", package: "xlsxwriter"),
                .product(name: "TextFileKit", package: "TextFileKit"),
                .product(name: "TimecodeKitCore", package: "TimecodeKit"),
                .product(name: "DAWFileKit", package: "DAWFileKit"),
                "OTCore"
            ],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "MarkersExtractorTests",
            dependencies: [
                "MarkersExtractor",
                .product(name: "TestingExtensions", package: "swift-testing-extensions")
            ],
            resources: [.copy("TestResource/Media Files")],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .executableTarget(
            name: "MarkersExtractorCLI",
            dependencies: [
                "MarkersExtractor",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ], 
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        )
    ]
)
