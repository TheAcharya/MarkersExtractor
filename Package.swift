// swift-tools-version: 6.2
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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.10.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.4.0"),
        .package(url: "https://github.com/TheAcharya/XLKit.git", from: "1.1.2"),
        .package(
            url: "https://github.com/orchetect/swift-daw-file-tools",
            from: "0.9.0",
            traits: [.trait(name: "FCP"), .trait(name: "MIDIFile"), .trait(name: "SRT")]
        ),
        .package(url: "https://github.com/orchetect/swift-extensions", from: "2.1.5"),
        .package(url: "https://github.com/orchetect/swift-textfile", from: "0.5.1"),
        .package(url: "https://github.com/orchetect/swift-timecode", from: "3.0.0"),
        .package(url: "https://github.com/orchetect/swift-testing-extensions", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "MarkersExtractor",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "XLKit", package: "XLKit"),
                .product(name: "TextFile", package: "swift-textfile"),
                .product(name: "SwiftTimecodeAV", package: "swift-timecode"),
                .product(name: "SwiftTimecodeCore", package: "swift-timecode"),
                .product(name: "DAWFileTools", package: "swift-daw-file-tools"),
                .product(name: "SwiftExtensions", package: "swift-extensions")
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
