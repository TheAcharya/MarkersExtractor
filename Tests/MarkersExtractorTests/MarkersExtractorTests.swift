//
//  MarkersExtractorTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Testing
import TestingExtensions
import TimecodeKitCore
@testable import MarkersExtractor

@Suite struct MarkersExtractorTests {
    @Test func findDuplicateIDs_inMarkers() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: ""),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .timelineNameAndTimecode
        
        let extractor = MarkersExtractor(settings: settings)
        
        func makeMarker(_ name: String, position: Timecode.Components) -> Marker {
            Marker(
                type: .marker(.standard),
                name: name,
                notes: "",
                roles: .init(video: "Video", audio: nil),
                position: tc(position, at: .fps24),
                parentInfo: .init(
                    clipType: FinalCutPro.FCPXML.ElementType.video.name,
                    clipName: "Some Clip",
                    clipInTime: tc("00:00:00:00", at: .fps24),
                    clipOutTime: tc("01:00:00:00", at: .fps24),
                    clipKeywords: [],
                    libraryName: "MyLibrary",
                    eventName: "Some Event",
                    projectName: "MyProject",
                    timelineName: "MyProject",
                    timelineStartTime: tc("01:00:00:00", at: .fps24)
                ), 
                metadata: .init(
                    reel: "Some reel",
                    scene: "Some scene",
                    take: "Some take"
                )
            )
        }
        
        let marker1 = makeMarker("marker1", position: .init(f: 1))
        let marker2 = makeMarker("marker2", position: .init(f: 2))
        
        #expect(
            extractor.findDuplicateIDs(in: []) == []
        )
        
        #expect(
            extractor.findDuplicateIDs(in: [marker1]) == []
        )
        
        #expect(
            extractor.findDuplicateIDs(in: [marker1, marker2]) == []
        )
        
        #expect(
            extractor.findDuplicateIDs(in: [marker1, marker1]) ==
            [marker1.id(settings.idNamingMode, tcStringFormat: extractor.timecodeStringFormat)]
        )
        
        #expect(
            extractor.findDuplicateIDs(in: [marker2, marker1, marker2]) ==
            [marker2.id(settings.idNamingMode, tcStringFormat: extractor.timecodeStringFormat)]
        )
    }
    
    @Test func isAllUniqueIDNonEmpty_inMarkers() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: ""),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .name
        
        let extractor = MarkersExtractor(settings: settings)
        
        func makeMarker(_ name: String, position: Timecode.Components) -> Marker {
            Marker(
                type: .marker(.standard),
                name: name,
                notes: "",
                roles: .init(video: "Video", audio: nil),
                position: tc(position, at: .fps24), 
                parentInfo: .init(
                    clipType: FinalCutPro.FCPXML.ElementType.video.name,
                    clipName: "Some Clip",
                    clipInTime: tc("00:00:00:00", at: .fps24),
                    clipOutTime: tc("01:00:00:00", at: .fps24),
                    clipKeywords: [],
                    libraryName: "MyLibrary",
                    eventName: "Some Event",
                    projectName: "MyProject",
                    timelineName: "MyProject",
                    timelineStartTime: tc("01:00:00:00", at: .fps24)
                ),
                metadata: .init(
                    reel: "Some reel",
                    scene: "Some scene",
                    take: "Some take"
                )
            )
        }
        
        let marker1 = makeMarker("marker1", position: .init(f: 1))
        let marker2 = makeMarker("", position: .init(f: 2))
        
        #expect(
            extractor.isAllUniqueIDNonEmpty(in: [])
        )
        
        #expect(
            extractor.isAllUniqueIDNonEmpty(in: [marker1])
        )
        
        #expect(
            !extractor.isAllUniqueIDNonEmpty(in: [marker1, marker2])
        )
        
        #expect(
            !extractor.isAllUniqueIDNonEmpty(in: [marker2])
        )
    }
}
