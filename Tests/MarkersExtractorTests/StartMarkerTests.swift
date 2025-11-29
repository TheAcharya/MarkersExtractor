//
//  StartMarkerTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Testing
import TestingExtensions
import SwiftTimecodeCore
@testable import MarkersExtractor

@Suite struct StartMarkerTests {
    /// Test if a marker at the exact start of a timeline is extracted correctly.
    @Test func startMarker_extractMarkers() async throws {
        let outputDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: outputDir
        )
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers().markers
        
        #expect(markers.count == 2)
        
        let fr: TimecodeFrameRate = .fps24
        
        let marker0 = try #require(markers[safe: 0])
        #expect(marker0.name == "Marker 1")
        #expect(marker0.position == tc("01:00:00:00", at: fr))
        
        let marker1 = try #require(markers[safe: 1])
        #expect(marker1.name == "Marker 2")
        #expect(marker1.position == tc("01:00:01:00", at: fr))
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.13">
    <resources>
        <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
    </resources>
    <library location="file:///Users/user/Movies/FCPXMLTest.fcpbundle/">
        <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
            <project name="Test Project" uid="3126B3B1-6552-432D-BA09-FD2BD6527B16" modDate="2025-02-10 23:19:30 -0800">
                <sequence format="r1" duration="96400/9600s" tcStart="3600s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <title ref="r2" offset="3600s" name="Basic Title" start="3600s" duration="24100/2400s">
                            <text>
                                <text-style ref="ts1">Title</text-style>
                            </text>
                            <text-style-def id="ts1">
                                <text-style font="Helvetica" fontSize="63" fontFace="Regular" fontColor="1 1 1 1" alignment="center"/>
                            </text-style-def>
                            <marker start="3600s" duration="100/2400s" value="Marker 1"/>
                            <marker start="3601s" duration="100/2400s" value="Marker 2"/>
                        </title>
                    </spine>
                </sequence>
            </project>
        </event>
    </library>
</fcpxml>
"""
