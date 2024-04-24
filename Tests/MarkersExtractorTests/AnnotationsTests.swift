//
//  AnnotationsTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@testable import MarkersExtractor
import OTCore
import TimecodeKit
import XCTest

final class AnnotationsTests: XCTestCase {
    // TODO: add test for filtering disabled captions once that's implemented
    /// Test importing captions
    func testAnnotations_CaptionsOnly() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .projectTimecode
        settings.markersSource = .captions
        settings.includeDisabled = true
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers()
        
        XCTAssertEqual(markers.count, 2)
        
        let fr: TimecodeFrameRate = .fps25
        
        let marker0 = try XCTUnwrap(markers[safe: 0])
        XCTAssertEqual(marker0.type, .caption)
        XCTAssertEqual(marker0.name, "caption1")
        XCTAssertEqual(marker0.notes, "")
        XCTAssertEqual(marker0.roles.audio?.map(\.rawValue), ["Dialogue"]) // inherited from clip it's anchored on (TODO: ?)
        XCTAssertEqual(marker0.roles.video?.rawValue, nil)
        XCTAssertEqual(marker0.roles.caption?.rawValue, "iTT?captionFormat=ITT.en")
        XCTAssertEqual(marker0.position, tc("01:00:03:00", at: fr))
        
        let marker1 = try XCTUnwrap(markers[safe: 1])
        XCTAssertEqual(marker1.type, .caption)
        XCTAssertEqual(marker1.name, "caption2")
        XCTAssertEqual(marker1.notes, "")
        XCTAssertEqual(marker1.roles.audio?.map(\.rawValue), ["Dialogue"]) // inherited from clip it's anchored on (TODO: ?)
        XCTAssertEqual(marker1.roles.video?.rawValue, nil)
        XCTAssertEqual(marker1.roles.caption?.rawValue, "iTT?captionFormat=ITT.en")
        XCTAssertEqual(marker1.position, tc("01:00:09:10", at: fr))
    }
    
    /// Test importing captions
    func testAnnotations_MarkersAndCaptions() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .projectTimecode
        settings.markersSource = .markersAndCaptions
        settings.includeDisabled = true
        
        let extractor = MarkersExtractor(settings: settings)
        
        // verify marker contents
        
        let markers = try await extractor.extractMarkers()
        
        XCTAssertEqual(markers.count, 3)
        
        let fr: TimecodeFrameRate = .fps25
        
        let marker0 = try XCTUnwrap(markers[safe: 0])
        XCTAssertEqual(marker0.type, .caption)
        XCTAssertEqual(marker0.name, "caption1")
        XCTAssertEqual(marker0.notes, "")
        XCTAssertEqual(marker0.roles.audio?.map(\.rawValue), ["Dialogue"]) // inherited from clip it's anchored on (TODO: ?)
        XCTAssertEqual(marker0.roles.video?.rawValue, nil)
        XCTAssertEqual(marker0.roles.caption?.rawValue, "iTT?captionFormat=ITT.en")
        XCTAssertEqual(marker0.position, tc("01:00:03:00", at: fr))
        
        let marker1 = try XCTUnwrap(markers[safe: 1])
        XCTAssertEqual(marker1.type, .caption)
        XCTAssertEqual(marker1.name, "caption2")
        XCTAssertEqual(marker1.notes, "")
        XCTAssertEqual(marker1.roles.audio?.map(\.rawValue), ["Dialogue"]) // inherited from clip it's anchored on (TODO: ?)
        XCTAssertEqual(marker1.roles.video?.rawValue, nil)
        XCTAssertEqual(marker1.roles.caption?.rawValue, "iTT?captionFormat=ITT.en")
        XCTAssertEqual(marker1.position, tc("01:00:09:10", at: fr))
        
        let marker2 = try XCTUnwrap(markers[safe: 2])
        XCTAssertEqual(marker2.type, .marker(.standard))
        XCTAssertEqual(marker2.name, "marker1")
        XCTAssertEqual(marker2.notes, "m1 notes")
        XCTAssertEqual(marker2.roles.audio?.map(\.rawValue), ["Dialogue"]) // inherited from clip it's anchored on (TODO: ?)
        XCTAssertEqual(marker2.roles.video?.rawValue, nil)
        XCTAssertEqual(marker2.roles.caption?.rawValue, nil)
        XCTAssertEqual(marker2.position, tc("01:00:27:10", at: fr))
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.11">
    <resources>
        <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <asset id="r2" name="TestVideo" uid="30C3729DCEE936129873D803DC13B623" start="0s" duration="738000/25000s" hasVideo="1" format="r3" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" audioRate="44100">
            <media-rep kind="original-media" sig="30C3729DCEE936129873D803DC13B623" src="file:///Users/user/Movies/MyLibrary.fcpbundle/Test%20Event/Original%20Media/TestVideo.m4v">
            </media-rep>
            <metadata>
                <md key="com.apple.proapps.studio.rawToLogConversion" value="0"/>
                <md key="com.apple.proapps.spotlight.kMDItemProfileName" value="SD (6-1-6)"/>
                <md key="com.apple.proapps.studio.cameraISO" value="0"/>
                <md key="com.apple.proapps.studio.cameraColorTemperature" value="0"/>
                <md key="com.apple.proapps.spotlight.kMDItemCodecs">
                    <array>
                        <string>'avc1'</string>
                        <string>MPEG-4 AAC</string>
                    </array>
                </md>
                <md key="com.apple.proapps.mio.ingestDate" value="2023-01-01 19:46:28 -0800"/>
            </metadata>
        </asset>
        <format id="r3" name="FFVideoFormat640x480p25" frameDuration="100/2500s" width="640" height="480" colorSpace="6-1-6 (Rec. 601 (NTSC))"/>
    </resources>
    <library location="file:///Users/user/Movies/MyLibrary.fcpbundle/">
        <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
            <project name="Annotations" uid="9FE87153-B0B8-4095-AABB-A92EADA46CAA" modDate="2023-11-17 15:37:05 -0800">
                <sequence format="r1" duration="35424000/1200000s" tcStart="3600s" tcFormat="NDF" audioLayout="stereo" audioRate="48k" keywords="keyword1">
                    <spine>
                        <asset-clip ref="r2" offset="3600s" name="TestVideo Clip" duration="35424000/1200000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                            <note>c1 notes</note>
                            <adjust-colorConform enabled="1" autoOrManual="manual" conformType="conformNone" peakNitsOfPQSource="1000" peakNitsOfSDRToPQSource="203"/>
                            <caption lane="1" offset="3s" name="caption1" start="3600s" duration="4s" enabled="0" role="iTT?captionFormat=ITT.en">
                                <text placement="bottom">
                                    <text-style ref="ts1">caption1 text</text-style>
                                </text>
                                <text-style-def id="ts1">
                                    <text-style font=".AppleSystemUIFont" fontSize="13" fontFace="Regular" fontColor="1 1 1 1" backgroundColor="0 0 0 1" tabStops="28L 56L 84L 112L 140L 168L 196L 224L 252L 280L 308L 336L"/>
                                </text-style-def>
                            </caption>
                            <caption lane="1" offset="23500/2500s" name="caption2" start="3600s" duration="2s" role="iTT?captionFormat=ITT.en">
                                <text placement="bottom">
                                    <text-style ref="ts2">caption2 text</text-style>
                                </text>
                                <text-style-def id="ts2">
                                    <text-style font=".AppleSystemUIFont" fontSize="13" fontFace="Regular" fontColor="1 1 1 1" backgroundColor="0 0 0 1" tabStops="28L 56L 84L 112L 140L 168L 196L 224L 252L 280L 308L 336L"/>
                                </text-style-def>
                            </caption>
                            <keyword start="0s" duration="738000/25000s" value="keyword1" note="k1 notes"/>
                            <keyword start="79/5s" duration="211000/25000s" value="keyword2" note="k2 notes"/>
                            <marker start="137/5s" duration="1000/25000s" value="marker1" note="m1 notes"/>
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
