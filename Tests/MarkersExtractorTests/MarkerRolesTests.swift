//
//  MarkerRolesTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@testable import MarkersExtractor
import XCTest

final class MarkerRolesTests: XCTestCase {
    func testVerbatim() {
        let markerRoles = MarkerRoles(
            video: "My Video Role.My Video Role-1",
            isVideoDefault: false,
            audio: ["My Audio Role.My Audio Role-1"],
            isAudioDefault: false,
            caption: "My Caption Role?captionFormat=ITT.en",
            isCaptionDefault: false,
            collapseSubroles: false
        )
        
        XCTAssertEqual(markerRoles.videoFormatted(), "My Video Role.My Video Role-1")
        XCTAssertEqual(markerRoles.audioFormatted(multipleRoleSeparator: ",").flat, "My Audio Role.My Audio Role-1")
        XCTAssertEqual(markerRoles.audioFormatted(multipleRoleSeparator: ",").array, ["My Audio Role.My Audio Role-1"])
        XCTAssertEqual(markerRoles.captionFormatted(), "My Caption Role")
    }
    
    func testCollapsedSubRole() {
        let markerRoles = MarkerRoles(
            video: "My Video Role.My Video Role-1",
            isVideoDefault: false,
            audio: ["My Audio Role.My Audio Role-1"],
            isAudioDefault: false,
            caption: "My Caption Role?captionFormat=ITT.en",
            isCaptionDefault: false,
            collapseSubroles: true
        )
        
        XCTAssertEqual(markerRoles.videoFormatted(), "My Video Role")
        XCTAssertEqual(markerRoles.audioFormatted(multipleRoleSeparator: ",").flat, "My Audio Role")
        XCTAssertEqual(markerRoles.audioFormatted(multipleRoleSeparator: ",").array, ["My Audio Role"])
        XCTAssertEqual(markerRoles.captionFormatted(), "My Caption Role")
    }
    
    func testIsDefault() {
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefault, true)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault, false)
        
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefault, true)
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"], isAudioDefault: false).isAudioDefault, false)
        
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefault, true)
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"], isAudioDefault: false).isAudioDefault, false)
        
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isAudioDefault, false)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault, false)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: false).isCaptionDefault, false)
    }
    
    func testIsEmpty() {
        XCTAssertEqual(MarkerRoles(video: nil).isVideoEmpty, true)
        XCTAssertEqual(MarkerRoles(video: "").isVideoEmpty, true)
        XCTAssertEqual(MarkerRoles(video: "Video").isVideoEmpty, false)
        
        XCTAssertEqual(MarkerRoles(audio: nil).isAudioEmpty, true)
        XCTAssertEqual(MarkerRoles(audio: [""]).isAudioEmpty, true)
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"]).isAudioEmpty, false)
    }
    
    func testIsDefined() {
        XCTAssertEqual(MarkerRoles(video: nil).isVideoDefined, false)
        XCTAssertEqual(MarkerRoles(video: "").isVideoDefined, false)
        XCTAssertEqual(MarkerRoles(video: "Video").isVideoDefined, true)
        XCTAssertEqual(MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefined, false)
        
        XCTAssertEqual(MarkerRoles(audio: nil).isAudioDefined, false)
        XCTAssertEqual(MarkerRoles(audio: [""]).isAudioDefined, false)
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"]).isAudioDefined, true)
        XCTAssertEqual(MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefined, false)
    }
    
    func testMultipleAudio() {
        XCTAssertEqual(
            MarkerRoles(audio: ["Dialogue.MixL", "Dialogue.MixR"])
                .audioFormatted(multipleRoleSeparator: ",").flat,
            "Dialogue.MixL,Dialogue.MixR"
        )
        XCTAssertEqual(
            MarkerRoles(audio: ["Dialogue.MixL", "Dialogue.MixR"])
                .audioFormatted(multipleRoleSeparator: ",").array,
            ["Dialogue.MixL", "Dialogue.MixR"]
        )
    }
}
