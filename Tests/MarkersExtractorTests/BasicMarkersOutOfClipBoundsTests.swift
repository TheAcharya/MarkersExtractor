//
//  BasicMarkersOutOfClipBoundsTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Testing
import TestingExtensions
import TimecodeKitCore
@testable import MarkersExtractor

@Suite struct BasicMarkersOutOfClipBoundsTests {
    /// Ensure that markers that are out of bounds of clips are not included in extraction.
    /// Also tests to make sure marker parent clip information is correct.
    @Test func outOfClipBounds() async throws {
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        
        let extractor = MarkersExtractor(settings: settings)
        let markers = try await extractor.extractMarkers().markers
        
        // check clips
        
        let fr: TimecodeFrameRate = .fps25
        
        let clip1ParentInfo = Marker.ParentInfo(
            clipType: FinalCutPro.FCPXML.ElementType.assetClip.name,
            clipName: "Marker Test",
            // clipFilename: "Marker Test.m4v",
            clipInTime: tc("00:00:00:00", at: fr),
            clipOutTime: tc("00:00:20:20", at: fr), 
            clipKeywords: [],
            libraryName: "MyLibrary", 
            eventName: "Test Event",
            projectName: "Out of Bounds Markers",
            timelineName: "Out of Bounds Markers",
            timelineStartTime: tc("00:00:00:00", at: fr)
        )
        
        let clip2ParentInfo = Marker.ParentInfo(
            clipType: FinalCutPro.FCPXML.ElementType.assetClip.name,
            clipName: "Marker Test",
            // clipFilename: "Marker Test.m4v",
            clipInTime: tc("00:00:20:20", at: fr),
            clipOutTime: tc("00:00:41:15", at: fr),
            clipKeywords: [],
            libraryName: "MyLibrary", 
            eventName: "Test Event",
            projectName: "Out of Bounds Markers",
            timelineName: "Out of Bounds Markers",
            timelineStartTime: tc("00:00:00:00", at: fr)
        )
        
        // check markers
        
        #expect(markers.count == 2)
        
        // if the clip is the first clip on the timeline (it starts at 00:00:00:00) and
        // it had been resized from its left edge to result in an out-of-boundary marker prior to
        // the new clip start, the hidden marker's location
        
        // clip 1
        
        let marker0 = try #require(markers[safe: 0])
        #expect(marker0.name == "Marker 2")
        #expect(marker0.position == tc("00:00:07:23", at: fr))
        #expect(marker0.parentInfo == clip1ParentInfo)
        
        // clip 2
        
        let marker1 = try #require(markers[safe: 1])
        #expect(marker1.name == "Marker 5")
        #expect(marker1.position == tc("00:00:28:18", at: fr))
        #expect(marker1.parentInfo == clip2ParentInfo)
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.10">
<resources>
    <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
    <asset id="r2" name="Marker Test" uid="30C3729DCEE936129873D803DC13B623" start="0s" duration="738000/25000s" hasVideo="1" format="r3" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" audioRate="44100">
        <media-rep kind="original-media" sig="30C3729DCEE936129873D803DC13B623" src="file:///Users/stef/Movies/MyLibrary.fcpbundle/Test%20Event/Original%20Media/Marker%20Test.m4v">
        </media-rep>
    </asset>
    <format id="r3" name="FFVideoFormat640x480p25" frameDuration="100/2500s" width="640" height="480" colorSpace="6-1-6 (Rec. 601 (NTSC))"/>
</resources>
<library location="file:///Users/stef/Movies/MyLibrary.fcpbundle/">
    <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
        <project name="Out of Bounds Markers" uid="7FC150CE-7403-423A-8DC8-F290A5DB540F" modDate="2023-01-02 20:21:18 -0800">
            <sequence format="r1" duration="114600/2500s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                <spine>
                    <asset-clip ref="r2" offset="0s" name="Marker Test" start="11200/2500s" duration="52000/2500s" audioStart="0s" audioDuration="73800/2500s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <marker start="18/5s" duration="100/2500s" value="Marker 1"/>
                        <marker start="62/5s" duration="100/2500s" value="Marker 2"/>
                        <marker start="132/5s" duration="100/2500s" value="Marker 3"/>
                    </asset-clip>
                    <asset-clip ref="r2" offset="52000/2500s" name="Marker Test" start="11200/2500s" duration="52000/2500s" audioStart="0s" audioDuration="73800/2500s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <marker start="18/5s" duration="100/2500s" value="Marker 4"/>
                        <marker start="62/5s" duration="100/2500s" value="Marker 5"/>
                        <marker start="132/5s" duration="100/2500s" value="Marker 6"/>
                    </asset-clip>
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
