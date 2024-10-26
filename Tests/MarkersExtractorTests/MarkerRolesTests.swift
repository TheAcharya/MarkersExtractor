//
//  MarkerRolesTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Testing
import TestingExtensions
@testable import MarkersExtractor

@Suite struct MarkerRolesTests {
    @Test func verbatim() async {
        let markerRoles = MarkerRoles(
            video: "My Video Role.My Video Role-1",
            isVideoDefault: false,
            audio: ["My Audio Role.My Audio Role-1"],
            isAudioDefault: false,
            caption: "My Caption Role?captionFormat=ITT.en",
            isCaptionDefault: false,
            collapseSubroles: false
        )
        
        #expect(markerRoles.videoFormatted() == "My Video Role.My Video Role-1")
        #expect(markerRoles.audioFormatted(multipleRoleSeparator: ",").flat == "My Audio Role.My Audio Role-1")
        #expect(markerRoles.audioFormatted(multipleRoleSeparator: ",").array == ["My Audio Role.My Audio Role-1"])
        #expect(markerRoles.captionFormatted() == "My Caption Role")
    }
    
    @Test func collapsedSubRole() async {
        let markerRoles = MarkerRoles(
            video: "My Video Role.My Video Role-1",
            isVideoDefault: false,
            audio: ["My Audio Role.My Audio Role-1"],
            isAudioDefault: false,
            caption: "My Caption Role?captionFormat=ITT.en",
            isCaptionDefault: false,
            collapseSubroles: true
        )
        
        #expect(markerRoles.videoFormatted() == "My Video Role")
        #expect(markerRoles.audioFormatted(multipleRoleSeparator: ",").flat == "My Audio Role")
        #expect(markerRoles.audioFormatted(multipleRoleSeparator: ",").array == ["My Audio Role"])
        #expect(markerRoles.captionFormatted() == "My Caption Role")
    }
    
    @Test func isDefault() async {
        #expect(MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefault)
        #expect(!MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault)
        
        #expect(MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefault)
        #expect(!MarkerRoles(audio: ["Dialogue"], isAudioDefault: false).isAudioDefault)
        
        #expect(MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefault)
        #expect(!MarkerRoles(audio: ["Dialogue"], isAudioDefault: false).isAudioDefault)
        
        #expect(!MarkerRoles(video: "Video", isVideoDefault: true).isAudioDefault)
        #expect(!MarkerRoles(video: "Video", isVideoDefault: false).isVideoDefault)
        #expect(!MarkerRoles(video: "Video", isVideoDefault: false).isCaptionDefault)
    }
    
    @Test func isEmpty() async {
        #expect(MarkerRoles(video: nil).isVideoEmpty)
        #expect(MarkerRoles(video: "").isVideoEmpty)
        #expect(!MarkerRoles(video: "Video").isVideoEmpty)
        
        #expect(MarkerRoles(audio: nil).isAudioEmpty)
        #expect(MarkerRoles(audio: [""]).isAudioEmpty)
        #expect(!MarkerRoles(audio: ["Dialogue"]).isAudioEmpty)
    }
    
    @Test func isDefined() async {
        #expect(!MarkerRoles(video: nil).isVideoDefined)
        #expect(!MarkerRoles(video: "").isVideoDefined)
        #expect(MarkerRoles(video: "Video").isVideoDefined)
        #expect(!MarkerRoles(video: "Video", isVideoDefault: true).isVideoDefined)
        
        #expect(!MarkerRoles(audio: nil).isAudioDefined)
        #expect(!MarkerRoles(audio: [""]).isAudioDefined)
        #expect(MarkerRoles(audio: ["Dialogue"]).isAudioDefined)
        #expect(!MarkerRoles(audio: ["Dialogue"], isAudioDefault: true).isAudioDefined)
    }
    
    @Test func multipleAudio() async {
        #expect(
            MarkerRoles(audio: ["Dialogue.MixL", "Dialogue.MixR"])
                .audioFormatted(multipleRoleSeparator: ",").flat ==
            "Dialogue.MixL,Dialogue.MixR"
        )
        #expect(
            MarkerRoles(audio: ["Dialogue.MixL", "Dialogue.MixR"])
                .audioFormatted(multipleRoleSeparator: ",").array ==
            ["Dialogue.MixL", "Dialogue.MixR"]
        )
    }
}
