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
            MarkerRoles.collapseSubrole(role: role)
        }
        
        XCTAssertEqual(collapse("Video"), "Video")
        XCTAssertEqual(collapse("Video.Video-1"), "Video")
        XCTAssertEqual(collapse("Video.Video-2"), "Video")
        
        XCTAssertEqual(collapse("Video.Video-Something"), "Video.Video-Something")
        XCTAssertEqual(collapse("Video.Video-"), "Video.Video-")
    }
    
    func testIsDefault() {
        XCTAssertEqual(MarkerRoles(defaultForClipType: "title")?.isVideoDefault, true)
        
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefault, true)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault, false)
        
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isAudioDefault, false)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault, false)
    }
    
    func testIsEmpty() {
        XCTAssertEqual(MarkerRoles(video: nil).isVideoEmpty, true)
        XCTAssertEqual(MarkerRoles(video: "").isVideoEmpty, true)
        XCTAssertEqual(MarkerRoles(video: "Video").isVideoEmpty, false)
        
        XCTAssertEqual(MarkerRoles(audio: nil).isAudioEmpty, true)
        XCTAssertEqual(MarkerRoles(audio: "").isAudioEmpty, true)
        XCTAssertEqual(MarkerRoles(audio: "Dialogue").isAudioEmpty, false)
    }
    
    func testIsDefined() {
        XCTAssertEqual(MarkerRoles(video: nil).isVideoDefined, false)
        XCTAssertEqual(MarkerRoles(video: "").isVideoDefined, false)
        XCTAssertEqual(MarkerRoles(video: "Video").isVideoDefined, true)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefined, false)
        
        XCTAssertEqual(MarkerRoles(audio: nil).isAudioDefined, false)
        XCTAssertEqual(MarkerRoles(audio: "").isAudioDefined, false)
        XCTAssertEqual(MarkerRoles(audio: "Dialogue").isAudioDefined, true)
        XCTAssertEqual(MarkerRoles(audio: "Dialogue", isAudioDefault: true).isAudioDefined, false)
    }
}
