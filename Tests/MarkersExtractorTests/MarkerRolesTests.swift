//
//  MarkerRolesTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import XCTest
@testable import MarkersExtractor

final class MarkerRolesTests: XCTestCase {
    func testCollapseClipSubrole() throws {
        func collapse(_ role: String) -> String {
            MarkerRoles.collapseClipSubrole(role: role)
        }
        
        XCTAssertEqual(collapse("Video"), "Video")
        XCTAssertEqual(collapse("Video.Video-1"), "Video")
        XCTAssertEqual(collapse("Video.Video-2"), "Video")
        
        XCTAssertEqual(collapse("Video.Video-Something"), "Video.Video-Something")
        XCTAssertEqual(collapse("Video.Video-"), "Video.Video-")
    }
}
