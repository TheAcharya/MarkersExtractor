//
//  BasicMarkersEmptyIDTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Testing
import TestingExtensions
import SwiftTimecodeCore
@testable import MarkersExtractor

@Suite struct BasicMarkersEmptyIDTests {
    /// Ensure that empty marker ID strings cause an error and abort the conversion process.
    @Test(arguments: MarkerIDMode.allCases)
    func testBasicMarkers_extractMarkers_nonEmptyMarkerIDs(idMode: MarkerIDMode) async throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory
        )
        
        settings.idNamingMode = idMode
        
        let extractor = MarkersExtractor(settings: settings)
        
        // attempt to extract markers.
        switch idMode {
        case .timelineNameAndTimecode:
            // no way case an error since timecode will always be a non-empty string.
            // so just test that no error is thrown here.
            
            do {
                _ = try await extractor.extractMarkers()
            } catch {
                #fail("\(error.localizedDescription)")
            }
        case .name:
            // expect an error here - 3rd marker has an empty Name
            do {
                _ = try await extractor.extractMarkers()
                #fail("Expected error to be thrown.")
            } catch {
                // we want an error
            }
        case .notes:
            // expect an error here - 2nd marker has an empty Name
            do {
                _ = try await extractor.extractMarkers()
                #fail("Expected error to be thrown.")
            } catch {
                // we want an error
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
                            <marker start="7266259/2000s" duration="1001/30000s" value="Marker 1" completed="0" note=""/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="" completed="1" note="notes yay"/>
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
