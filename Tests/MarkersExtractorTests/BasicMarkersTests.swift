//
//  BasicMarkersTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Testing
import TestingExtensions
import TimecodeKitCore
@testable import MarkersExtractor

@Suite struct BasicMarkersTests {
    /// Basic test to check `MarkersExtractor.extractMarkers()` parses data correctly.
    ///
    /// Note that two markers share the same marker ID. This test also checks the default behavior
    /// of non-unique IDs.
    @Test func basicMarkers_extractMarkers() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .timelineNameAndTimecode
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers().markers
        
        #expect(markers.count == 4)
        
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
        
        let marker0 = try #require(markers[safe: 0])
        #expect(marker0.type == .marker(.standard))
        #expect(marker0.name == "Marker 1")
        #expect(marker0.notes == "some notes here")
        #expect(
            marker0.roles ==
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        #expect(marker0.position == tc("00:00:29:14", at: fr))
        #expect(marker0.parentInfo == parentInfo)
        #expect(marker0.xmlPath == "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/title[1]/marker[1]")
        
        let marker1 = try #require(markers[safe: 1])
        #expect(marker1.type == .marker(.toDo(completed: false)))
        #expect(marker1.name == "Marker 1")
        #expect(marker1.notes == "more notes here")
        #expect(
            marker1.roles ==
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        #expect(marker1.position == tc("00:00:29:15", at: fr))
        #expect(marker1.parentInfo == parentInfo)
        #expect(marker1.xmlPath == "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/title[1]/marker[2]")
        
        let marker2 = try #require(markers[safe: 2])
        #expect(marker2.type == .marker(.toDo(completed: true)))
        #expect(marker2.name == "Marker 2")
        #expect(marker2.notes == "notes yay")
        #expect(
            marker2.roles ==
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        #expect(marker2.position == tc("00:00:29:15", at: fr))
        #expect(marker2.parentInfo == parentInfo)
        #expect(marker2.xmlPath == "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/title[1]/marker[3]")
        
        let marker3 = try #require(markers[safe: 3])
        #expect(marker3.type == .marker(.chapter(posterOffset: Fraction(11, 30))))
        #expect(marker3.name == "Marker 3")
        #expect(marker3.notes == "more notes here")
        #expect(
            marker3.roles ==
            .init(video: "Titles", isVideoDefault: true, audio: nil, isAudioDefault: false)
        )
        #expect(marker3.position == tc("00:00:29:17", at: fr))
        #expect(marker3.parentInfo == parentInfo)
        #expect(marker3.xmlPath == "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/title[1]/chapter-marker[1]")
    }
    
    /// Ensure that duplicate marker ID uniquing works correctly for all marker ID naming modes.
    @Test func basicMarkers_extractMarkers_uniquing() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        
        for idMode in MarkerIDMode.allCases {
            settings.idNamingMode = idMode
            
            let extractor = MarkersExtractor(settings: settings)
            
            // extract and unique
            var markers = try await extractor.extractMarkers().markers
            markers = await extractor.uniquingMarkerIDs(in: markers)
            
            // verify correct IDs
            switch idMode {
            case .timelineNameAndTimecode:
                #expect(
                    await markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Test Project_00:00:29:14"
                )
                #expect(
                    await markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Test Project_00:00:29:15-1"
                )
                #expect(
                    await markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Test Project_00:00:29:15-2"
                )
                #expect(
                    await markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Test Project_00:00:29:17"
                )
            case .name:
                #expect(
                    await markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Marker 1-1"
                )
                #expect(
                    await markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Marker 1-2"
                )
                #expect(
                    await markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Marker 2"
                )
                #expect(
                    await markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "Marker 3"
                )
            case .notes:
                #expect(
                    await markers[safe: 0]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "some notes here"
                )
                #expect(
                    await markers[safe: 1]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "more notes here-1"
                )
                #expect(
                    await markers[safe: 2]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "notes yay"
                )
                #expect(
                    await markers[safe: 3]?.id(
                        settings.idNamingMode,
                        tcStringFormat: extractor.timecodeStringFormat
                    ) ==
                    "more notes here-2"
                )
            }
        }
    }
    
    @Test func basicMarkers_xPath() async throws {
        let xml = try XMLDocument(data: fcpxmlTestData)
        
        let marker0XPath = "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/title[1]/marker[1]"
        
        do {
            let settings = try MarkersExtractor.Settings(
                fcpxml: FCPXMLFile(fileContents: xml),
                outputDir: FileManager.default.temporaryDirectory
            )
            
            let extractor = MarkersExtractor(settings: settings)
            
            let markers = try await extractor.extractMarkers().markers
            
            let marker0 = try #require(markers[safe: 0])
            
            // verify XPath string
            #expect(marker0.xmlPath == marker0XPath)
        }
        
        // look up XPath
        let marker0Nodes = try xml.nodes(forXPath: marker0XPath)
        try #require(marker0Nodes.count == 1)
        let marker0Node = try #require(marker0Nodes.first?.asElement)
        let marker0AsMarker = try #require(marker0Node.fcpAsMarker)
        
        // verify marker
        #expect(marker0AsMarker.name == "Marker 1")
        #expect(marker0AsMarker.note == "some notes here")
        
        // mutate marker XML element
        marker0AsMarker.name = "Renamed Marker"
        marker0AsMarker.note = "new notes here"
        
        // verify updated marker in-place
        #expect(marker0AsMarker.name == "Renamed Marker")
        #expect(marker0AsMarker.note == "new notes here")
        
        do {
            let settings = try MarkersExtractor.Settings(
                fcpxml: FCPXMLFile(fileContents: xml),
                outputDir: FileManager.default.temporaryDirectory
            )
            
            let extractor = MarkersExtractor(settings: settings)
            
            let markers = try await extractor.extractMarkers().markers
            
            let marker0 = try #require(markers[safe: 0])
            
            // verify updated marker
            #expect(marker0.name == "Renamed Marker")
            #expect(marker0.notes == "new notes here")
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
