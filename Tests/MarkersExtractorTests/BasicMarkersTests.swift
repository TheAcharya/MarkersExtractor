//
//  BasicMarkersTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
@testable import MarkersExtractor
import TimecodeKit
import XCTest

final class BasicMarkersTests: XCTestCase {
    /// Basic test to check `MarkersExtractor.extractMarkers()` parses data correctly.
    ///
    /// Note that two markers share the same marker ID. This test also checks the default behavior
    /// of non-unique IDs.
    func testBasicMarkers_extractMarkers() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .timelineNameAndTimecode
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers().markers
        
        XCTAssertEqual(markers.count, 4)
        
        let fr: TimecodeFrameRate = .fps29_97
        
        let parentInfo = Marker.ParentInfo(
            clipType: FinalCutPro.FCPXML.ElementType.title.name,
            clipName: "Basic Title",
            clipInTime: tc("00:00:00:00", at: fr),
            clipOutTime: tc("00:01:03:29", at: fr),
            clipKeywords: [],
            libraryName: "MyLibrary",
            eventName: "Test Event",
            projectName: "Test Project",
            timelineName: "Test Project",
            timelineStartTime: tc("00:00:00:00", at: fr)
        )
        
        let marker0 = try XCTUnwrap(markers[safe: 0])
        XCTAssertEqual(marker0.type, .marker(.standard))
        XCTAssertEqual(marker0.name, "Marker 1")
        XCTAssertEqual(marker0.notes, "some notes here")
        XCTAssertEqual(
            marker0.roles,
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        XCTAssertEqual(marker0.position, tc("00:00:29:14", at: fr))
        XCTAssertEqual(marker0.parentInfo, parentInfo)
        
        let marker1 = try XCTUnwrap(markers[safe: 1])
        XCTAssertEqual(marker1.type, .marker(.toDo(completed: false)))
        XCTAssertEqual(marker1.name, "Marker 1")
        XCTAssertEqual(marker1.notes, "more notes here")
        XCTAssertEqual(
            marker1.roles,
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        XCTAssertEqual(marker1.position, tc("00:00:29:15", at: fr))
        XCTAssertEqual(marker1.parentInfo, parentInfo)
        
        let marker2 = try XCTUnwrap(markers[safe: 2])
        XCTAssertEqual(marker2.type, .marker(.toDo(completed: true)))
        XCTAssertEqual(marker2.name, "Marker 2")
        XCTAssertEqual(marker2.notes, "notes yay")
        XCTAssertEqual(
            marker2.roles,
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        XCTAssertEqual(marker2.position, tc("00:00:29:15", at: fr))
        XCTAssertEqual(marker2.parentInfo, parentInfo)
        
        let marker3 = try XCTUnwrap(markers[safe: 3])
        XCTAssertEqual(marker3.type, .marker(.chapter(posterOffset: Fraction(11, 30))))
        XCTAssertEqual(marker3.name, "Marker 3")
        XCTAssertEqual(marker3.notes, "more notes here")
        XCTAssertEqual(
            marker3.roles,
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        XCTAssertEqual(marker3.position, tc("00:00:29:17", at: fr))
        XCTAssertEqual(marker3.parentInfo, parentInfo)
    }
    
    /// Ensure that duplicate marker ID uniquing works correctly for all marker ID naming modes.
    func testBasicMarkers_extractMarkers_uniquing() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        
        for idMode in MarkerIDMode.allCases {
            settings.idNamingMode = idMode
            
            let extractor = MarkersExtractor(settings: settings)
            
            // extract and unique
            var markers = try await extractor.extractMarkers().markers
            markers = extractor.uniquingMarkerIDs(in: markers)
            
            // verify correct IDs
            switch idMode {
            case .timelineNameAndTimecode:
                XCTAssertEqual(
                    markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Test Project_00:00:29:14"
                )
                XCTAssertEqual(
                    markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Test Project_00:00:29:15-1"
                )
                XCTAssertEqual(
                    markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Test Project_00:00:29:15-2"
                )
                XCTAssertEqual(
                    markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Test Project_00:00:29:17"
                )
            case .name:
                XCTAssertEqual(
                    markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Marker 1-1"
                )
                XCTAssertEqual(
                    markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Marker 1-2"
                )
                XCTAssertEqual(
                    markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Marker 2"
                )
                XCTAssertEqual(
                    markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "Marker 3"
                )
            case .notes:
                XCTAssertEqual(
                    markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "some notes here"
                )
                XCTAssertEqual(
                    markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "more notes here-1"
                )
                XCTAssertEqual(
                    markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "notes yay"
                )
                XCTAssertEqual(
                    markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ),
                    "more notes here-2"
                )
            }
        }
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.9">
    <resources>
        <format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
    </resources>
    <library location="file:///Users/stef/Movies/MyLibrary.fcpbundle/">
        <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
            <project name="Test Project" uid="5F39A86E-B599-43BE-A080-B5F7AE2D41AF" modDate="2022-12-12 16:10:56 -0800">
                <sequence format="r1" duration="1920919/30000s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <title ref="r2" offset="0s" name="Basic Title" start="108108000/30000s" duration="1920919/30000s">
                            <text>
                                <text-style ref="ts1">Title</text-style>
                            </text>
                            <text-style-def id="ts1">
                                <text-style font="Helvetica" fontSize="63" fontFace="Regular" fontColor="1 1 1 1" alignment="center"/>
                            </text-style-def>
                            <marker start="27248221/7500s" duration="1001/30000s" value="Marker 1" note="some notes here"/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="Marker 1" completed="0" note="more notes here"/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="Marker 2" completed="1" note="notes yay"/>
                            <chapter-marker start="108995887/30000s" duration="1001/30000s" value="Marker 3" posterOffset="11/30s" note="more notes here"/>
                        </title>
                    </spine>
                </sequence>
            </project>
        </event>
        <smart-collection name="Projects" match="all">
            <match-clip rule="is" type="project"/>
        </smart-collection>
        <smart-collection name="All Video" match="any">
            <match-media rule="is" type="videoOnly"/>
            <match-media rule="is" type="videoWithAudio"/>
        </smart-collection>
        <smart-collection name="Audio Only" match="all">
            <match-media rule="is" type="audioOnly"/>
        </smart-collection>
        <smart-collection name="Stills" match="all">
            <match-media rule="is" type="stills"/>
        </smart-collection>
        <smart-collection name="Favorites" match="all">
            <match-ratings value="favorites"/>
        </smart-collection>
    </library>
</fcpxml>
"""
