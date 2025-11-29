//
//  MarkersExtractorTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Testing
import TestingExtensions
import SwiftTimecodeCore
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
                ),
                xmlPath: "" // not used here
            )
        }
        
        let marker1 = makeMarker("marker1", position: .init(f: 1))
        let marker2 = makeMarker("marker2", position: .init(f: 2))
        
        #expect(
            await extractor.findDuplicateIDs(in: []) == []
        )
        
        #expect(
            await extractor.findDuplicateIDs(in: [marker1]) == []
        )
        
        #expect(
            await extractor.findDuplicateIDs(in: [marker1, marker2]) == []
        )
        
        #expect(
            await extractor.findDuplicateIDs(in: [marker1, marker1]) ==
            [marker1.id(settings.idNamingMode, tcStringFormat: extractor.timecodeStringFormat)]
        )
        
        #expect(
            await extractor.findDuplicateIDs(in: [marker2, marker1, marker2]) ==
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
                ),
                xmlPath: "" // not used here
            )
        }
        
        let marker1 = makeMarker("marker1", position: .init(f: 1))
        let marker2 = makeMarker("", position: .init(f: 2))
        
        #expect(
            await extractor.isAllUniqueIDNonEmpty(in: [])
        )
        
        #expect(
            await extractor.isAllUniqueIDNonEmpty(in: [marker1])
        )
        
        #expect(
            await !extractor.isAllUniqueIDNonEmpty(in: [marker1, marker2])
        )
        
        #expect(
            await !extractor.isAllUniqueIDNonEmpty(in: [marker2])
        )
    }
}
