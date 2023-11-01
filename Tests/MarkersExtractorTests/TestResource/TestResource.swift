//
//  TestResource.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import XCTest

// NOTE: DO NOT name any folders "Resources". Xcode will fail to build iOS targets.

// MARK: - Constants

/// Resources files on disk used for unit testing.
enum TestResource: CaseIterable {
    static let videoTrack_29_97_Start_00_00_00_00 = TestResource.File(
        name: "VideoTrack_29_97_Start-00-00-00-00", ext: "mp4", subFolder: "Media Files"
    )
}

// MARK: - Utilities

extension TestResource {
    struct File: Equatable, Hashable {
        let name: String
        let ext: String
        let subFolder: String?
        
        var fileName: String { name + "." + ext }
    }
}

extension TestResource.File {
    func url(
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> URL {
        // Bundle.module is synthesized when the package target has `resources: [...]`
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: subFolder
        )
        else {
            var msg = message()
            msg = msg.isEmpty ? "" : ": \(msg)"
            XCTFail(
                "Could not form URL, possibly could not find file.\(msg)",
                file: file,
                line: line
            )
            throw XCTSkip()
        }
        return url
    }
    
    func data(
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Data {
        let url = try url()
        guard let data = try? Data(contentsOf: url)
        else {
            var msg = message()
            msg = msg.isEmpty ? "" : ": \(msg)"
            XCTFail(
                "Could not read file at URL: \(url.absoluteString).",
                file: file,
                line: line
            )
            throw XCTSkip("Aborting test.")
        }
        return data
    }
}
