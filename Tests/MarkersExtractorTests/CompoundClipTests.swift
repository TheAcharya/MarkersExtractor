//
//  CompoundClipTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import OTCore
import Testing
import TestingExtensions
import TimecodeKitCore
@testable import MarkersExtractor

@Suite struct CompoundClipTests {
    /// Ensure that markers directly attached to compound clips (`ref-clip`s) on the main timeline
    /// are preserved, while all markers within compound clips are discarded.
    @Test func compoundClips() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .timelineNameAndTimecode
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers().markers
        
        #expect(markers.count == 1)
        
        let fr: TimecodeFrameRate = .fps25
        
        // just test basic marker info to identify the marker
        let marker0 = try #require(markers[safe: 0])
        #expect(marker0.name == "Marker On Compound Clip in Main Timeline")
        #expect(marker0.position == tc("01:00:04:00", at: fr))
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.11">
    <resources>
        <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <media id="r2" name="Title Compound Clip" uid="0E1m58IaTwGcKXmpSkdu7w" modDate="2023-11-22 13:48:58 -0800">
            <sequence format="r1" duration="25100/2500s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                <spine>
                    <title ref="r3" offset="0s" name="Basic Title" start="3600s" duration="25100/2500s">
                        <text>
                            <text-style ref="ts1">Title</text-style>
                        </text>
                        <text-style-def id="ts1">
                            <text-style font="Helvetica" fontSize="63" fontFace="Regular" fontColor="1 1 1 1" alignment="center"/>
                        </text-style-def>
                        <marker start="3606s" duration="100/2500s" value="Marker On Title Clip Within Title Compound Clip"/>
                    </title>
                </spine>
            </sequence>
        </media>
        <effect id="r3" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
        <media id="r4" name="Clouds Compound Clip" uid="D/iIRR4hTFGiQC/zaT4Bzw" modDate="2023-11-22 13:48:58 -0800">
            <sequence format="r1" duration="50100/2500s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                <spine>
                    <video ref="r5" offset="0s" name="Clouds" start="3600s" duration="10s">
                        <marker start="3605s" duration="100/2500s" value="Marker Within Clouds Compound Clip"/>
                    </video>
                    <ref-clip ref="r2" offset="10s" name="Title Compound Clip" duration="25100/2500s">
                        <marker start="6s" duration="100/2500s" value="Marker on Title Compound Clip Within Clouds Compound Clip"/>
                    </ref-clip>
                </spine>
            </sequence>
        </media>
        <effect id="r5" name="Clouds" uid=".../Generators.localized/Backgrounds.localized/Clouds.localized/Clouds.motn"/>
    </resources>
    <library location="file:///Users/stef/Movies/MyLibrary.fcpbundle/">
        <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
            <project name="CompoundClip" uid="2CE6EE34-600B-4926-B438-1BD3E3B30A78" modDate="2023-11-22 13:48:58 -0800">
                <sequence format="r1" duration="200400/10000s" tcStart="3600s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <ref-clip ref="r2" offset="3600s" name="Title Compound Clip" duration="100400/10000s">
                            <marker start="4s" duration="100/2500s" value="Marker On Compound Clip in Main Timeline"/>
                        </ref-clip>
                        <ref-clip ref="r4" offset="36100400/10000s" name="Clouds Compound Clip" duration="10s"/>
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
