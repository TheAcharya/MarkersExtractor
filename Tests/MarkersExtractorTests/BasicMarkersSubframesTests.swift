//
//  BasicMarkersSubframesTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Testing
import TestingExtensions
import SwiftTimecodeCore
@testable import MarkersExtractor

@Suite struct BasicMarkersSubframesTests {
    /// Test that fraction time values that have subframes correctly convert to Timecode.
    @Test func basicMarkers_extractMarkers_TimecodeSubframes() async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.enableSubframes = true
        
        let extractor = MarkersExtractor(settings: settings)
        let markers = try await extractor.extractMarkers().markers.sorted()
        
        // 24 total markers.
        // 6 markers are ignored because they are within compound clips (the 2 instances of the
        // `ref-clip` which contains 3 markers).
        #expect(markers.count == 18)
        
        let lastMarker = try #require(markers.last)
        #expect(
            lastMarker.positionTimeString(format: .timecode(stringFormat: [.showSubFrames])) ==
            "00:00:28:19.25"
        )
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.10">
<resources>
    <format id="r1" name="FFVideoFormatDV720x576i50" frameDuration="200/5000s" fieldOrder="lower first" width="720" height="576" paspH="59" paspV="54" colorSpace="5-1-6 (Rec. 601 (PAL))"/>
    <asset id="r2" name="Test Video (29.97 fps)" uid="554B59605B289ECE8057E7FECBC3D3D0" start="0s" duration="101869/1000s" hasVideo="1" format="r3" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" audioRate="48000">
        <media-rep kind="original-media" sig="554B59605B289ECE8057E7FECBC3D3D0" src="file:///Users/stef/Desktop/Marker_Interlaced.fcpbundle/11-9-22/Original%20Media/Test%20Video%20(29.97%20fps).mp4">
        </media-rep>
        <metadata>
            <md key="com.apple.proapps.studio.rawToLogConversion" value="0"/>
            <md key="com.apple.proapps.spotlight.kMDItemProfileName" value="HD (1-1-1)"/>
            <md key="com.apple.proapps.studio.cameraISO" value="0"/>
            <md key="com.apple.proapps.studio.cameraColorTemperature" value="0"/>
            <md key="com.apple.proapps.spotlight.kMDItemCodecs">
                <array>
                    <string>'avc1'</string>
                    <string>MPEG-4 AAC</string>
                </array>
            </md>
            <md key="com.apple.proapps.mio.ingestDate" value="2022-09-10 19:25:11 -0700"/>
        </metadata>
    </asset>
    <format id="r3" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
    <media id="r4" name="29.97_CC" uid="GYR/OKBAQ/2tErV+GGXCuA" modDate="2022-09-10 23:08:42 -0700">
        <sequence format="r3" duration="174174/30000s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
            <spine>
                <asset-clip ref="r2" offset="0s" name="Test Video (29.97 fps)" start="452452/30000s" duration="174174/30000s" tcFormat="NDF" audioRole="dialogue">
                    <marker start="247247/15000s" duration="1001/30000s" value="Marker 5"/>
                    <marker start="181181/10000s" duration="1001/30000s" value="Marker 6"/>
                    <marker start="49049/2500s" duration="1001/30000s" value="Marker 7"/>
                </asset-clip>
            </spine>
        </sequence>
    </media>
    <effect id="r5" name="Black &amp; White" uid=".../Effects.localized/Color.localized/Black &amp; White.localized/Black &amp; White.moef"/>
    <effect id="r6" name="Colorize" uid=".../Effects.localized/Color.localized/Colorize.localized/Colorize.moef"/>
</resources>
<library location="file:///Users/stef/Desktop/Marker_Interlaced.fcpbundle/">
    <event name="11-9-22" uid="061C8BEC-DA79-445F-A7A8-CF84F1A7448A">
        <project name="25i_V1" uid="136139D9-8DDC-4593-B09E-570FBE55A761" modDate="2022-12-30 20:47:39 -0800">
            <sequence format="r1" duration="147600/5000s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                <spine>
                    <asset-clip ref="r2" offset="0s" name="Test Video (29.97 fps)" duration="17000/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                        <marker start="11011/7500s" duration="1001/30000s" value="Marker 2"/>
                    </asset-clip>
                    <asset-clip ref="r2" offset="17000/5000s" name="Test Video (29.97 fps)" start="35702/5000s" duration="17600/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                        <marker start="239239/30000s" duration="1001/30000s" value="Marker 3"/>
                        <marker start="287287/30000s" duration="1001/30000s" value="Marker 4"/>
                    </asset-clip>
                    <ref-clip ref="r4" offset="34600/5000s" name="29.97_CC" duration="18000/5000s">
                        <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                    </ref-clip>
                    <asset-clip ref="r2" offset="52600/5000s" name="Test Video (29.97 fps)" start="71238/5000s" duration="16800/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <timeMap>
                            <timept time="0s" value="0s" interp="smooth2"/>
                            <timept time="4436211/90000s" value="9168210/90000s" interp="smooth2"/>
                        </timeMap>
                        <marker start="154573/10000s" duration="1001/30000s" value="Marker 8"/>
                        <marker start="501757/30000s" duration="1001/30000s" value="Marker 9"/>
                    </asset-clip>
                    <asset-clip ref="r2" offset="69400/5000s" name="Test Video (29.97 fps)" start="216883/5000s" duration="22800/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                        <spine lane="1" offset="220883/5000s" format="r1">
                            <asset-clip ref="r2" offset="0s" name="Test Video (29.97 fps)" start="281782/5000s" duration="1000/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                                <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                                <filter-video ref="r5" name="Black &amp; White"/>
                            </asset-clip>
                            <asset-clip ref="r2" offset="1000/5000s" name="Test Video (29.97 fps)" start="283617/5000s" duration="1400/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                                <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                                <marker start="851851/15000s" duration="1001/30000s" value="Marker 14"/>
                                <marker start="853853/15000s" duration="1001/30000s" value="Marker 15"/>
                                <filter-video ref="r5" name="Black &amp; White"/>
                            </asset-clip>
                            <asset-clip ref="r2" offset="2400/5000s" name="Test Video (29.97 fps)" start="286787/5000s" duration="1400/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                                <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                                <filter-video ref="r5" name="Black &amp; White"/>
                            </asset-clip>
                            <asset-clip ref="r2" offset="3800/5000s" name="Test Video (29.97 fps)" start="289956/5000s" duration="1200/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                                <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                                <marker start="871871/15000s" duration="1001/30000s" value="Marker 17"/>
                                <filter-video ref="r5" name="Black &amp; White"/>
                            </asset-clip>
                        </spine>
                        <marker start="109109/2500s" duration="1001/30000s" value="Marker 1"/>
                        <marker start="1314313/30000s" duration="1001/30000s" value="Marker 10"/>
                        <marker start="11011/250s" duration="1001/30000s" value="Marker 11"/>
                        <marker start="1328327/30000s" duration="1001/30000s" value="Marker 12"/>
                        <marker start="673673/15000s" duration="1001/30000s" value="Marker 16"/>
                    </asset-clip>
                    <asset-clip ref="r2" offset="92200/5000s" name="Test Video (29.97 fps)" start="184851/5000s" duration="20800/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <timeMap>
                            <timept time="0s" value="0s" interp="smooth2"/>
                            <timept time="4681557/90000s" value="9168210/90000s" interp="smooth2"/>
                        </timeMap>
                        <marker start="76681/2000s" duration="1001/30000s" value="Marker 18"/>
                        <marker start="1206271/30000s" duration="1001/30000s" value="Marker 19"/>
                    </asset-clip>
                    <asset-clip ref="r2" offset="113000/5000s" name="Test Video (29.97 fps)" start="446112/5000s" duration="34600/5000s" format="r3" tcFormat="NDF" audioRole="dialogue">
                        <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                        <ref-clip ref="r4" lane="1" offset="56239/625s" name="29.97_CC" duration="2s">
                            <conform-rate scaleEnabled="0" srcFrameRate="29.97"/>
                            <filter-video ref="r6" name="Colorize"/>
                        </ref-clip>
                        <marker start="227227/2500s" duration="1001/30000s" value="Marker 20"/>
                        <marker start="187187/2000s" duration="1001/30000s" value="Marker 21"/>
                        <marker start="953953/10000s" duration="1001/30000s" value="Marker 22"/>
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
