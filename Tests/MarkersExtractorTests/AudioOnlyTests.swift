//
//  AudioOnlyTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@testable import MarkersExtractor
import OTCore
import TimecodeKitCore
import XCTest
import DAWFileKit

final class AudioOnlyTests: XCTestCase {
    func testAudioOnly() async throws {
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
        
        XCTAssertEqual(markers.count, 1)
        
        let fr: TimecodeFrameRate = .fps24
        
        let marker0 = try XCTUnwrap(markers[safe: 0])
        XCTAssertEqual(marker0.name, "Marker 1")
        XCTAssertEqual(marker0.position, tc("00:00:02:00", at: fr))
        
        XCTAssertEqual(marker0.roles.audio, [FinalCutPro.FCPXML.AudioRole(role: "Dialogue")])
        XCTAssertEqual(marker0.roles.isAudioDefault, false) // TODO: Dialogue isn't a builtin/default role??
        XCTAssertEqual(marker0.roles.isAudioEmpty, false)
        XCTAssertEqual(marker0.roles.isAudioDefined, true) // exists in the XML
        
        XCTAssertEqual(marker0.roles.video, nil)
        XCTAssertEqual(marker0.roles.isVideoDefault, false)
        XCTAssertEqual(marker0.roles.isVideoEmpty, true)
        XCTAssertEqual(marker0.roles.isVideoDefined, false) // was default, not defined
        
        XCTAssertEqual(marker0.roles.caption, nil)
    }
    
    /// Ensure that a placeholder thumbnail image is used for an audio-only clip.
    func testAudioOnly_WithMedia_PNG() async throws {
        let tempDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false)
        
        let dummyMediaData = try XCTUnwrap(EmbeddedResource.empty_mov.data)
        let dummyMediaURL = tempDir.appendingPathComponent("AudioOnly.mov")
        try dummyMediaData.write(to: dummyMediaURL)
        
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: tempDir,
            mediaSearchPaths: [tempDir],
            exportFormat: .notion,
            imageFormat: .still(.png)
        )
        
        let extractor = MarkersExtractor(settings: settings)
        
        // extract
        let result = try await extractor.extract()
        let exportDir = result.exportFolder
        
        // open folder (for manual debugging)
        // NSWorkspace.shared.open(exportDir)
        
        let dirContents = try FileManager.default.contentsOfDirectory(
            at: exportDir,
            includingPropertiesForKeys: [.nameKey]
        )
        
        let exportFilenames = dirContents.map(\.lastPathComponent)
        exportFilenames.forEach { print(" - " + $0) }
        
        // ensure that a placeholder thumbnail was used for the audio-only clip
        XCTAssertTrue(exportFilenames.contains("marker-placeholder.png"))
    }
    
    /// Ensure that a placeholder thumbnail image is used for an audio-only clip.
    func testAudioOnly_WithMedia_GIF() async throws {
        let tempDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false)
        
        let dummyMediaData = try XCTUnwrap(EmbeddedResource.empty_mov.data)
        let dummyMediaURL = tempDir.appendingPathComponent("AudioOnly.mov")
        try dummyMediaData.write(to: dummyMediaURL)
        
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: tempDir,
            mediaSearchPaths: [tempDir],
            exportFormat: .notion,
            imageFormat: .animated(.gif)
        )
        
        let extractor = MarkersExtractor(settings: settings)
        
        // extract
        let result = try await extractor.extract()
        let exportDir = result.exportFolder
        
        // open folder (for manual debugging)
        // NSWorkspace.shared.open(exportDir)
        
        let dirContents = try FileManager.default.contentsOfDirectory(
            at: exportDir,
            includingPropertiesForKeys: [.nameKey]
        )
        
        let exportFilenames = dirContents.map(\.lastPathComponent)
        exportFilenames.forEach { print(" - " + $0) }
        
        // ensure that a placeholder thumbnail was used for the audio-only clip
        XCTAssertTrue(exportFilenames.contains("marker-placeholder.gif"))
    }
}

private let fcpxmlTestData = fcpxmlTestString.data(using: .utf8)!
private let fcpxmlTestString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.11">
    <resources>
        <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <asset id="r2" name="TestAudio" uid="EB954597EA90C50869FFC27E7277E368" start="0s" duration="114688/22050s" hasAudio="1" audioSources="1" audioChannels="1" audioRate="22050">
            <media-rep kind="original-media" sig="EB954597EA90C50869FFC27E7277E368" src="file:///Users/user/Movies/FCPXMLTest.fcpbundle/Test%20Event/Original%20Media/TestAudio.wav">
            </media-rep>
            <metadata>
                <md key="com.apple.proapps.mio.ingestDate" value="2023-11-21 17:49:42 -0800"/>
            </metadata>
        </asset>
    </resources>
    <library location="file:///Users/user/Movies/FCPXMLTest.fcpbundle/">
        <event name="Test Event" uid="BB995477-20D4-45DF-9204-1B1AA44BE054">
            <project name="AudioOnly" uid="28DB8CA2-00E2-4BE5-A112-9EDA220212AB" modDate="2024-02-19 20:46:33 -0800">
                <sequence format="r1" duration="12400/2400s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="TestAudio" duration="12400/2400s" audioRole="dialogue">
                            <marker start="2s" duration="1/48000s" value="Marker 1"/>
                        </asset-clip>
                    </spine>
                </sequence>
            </project>
        </event>
    </library>
</fcpxml>
"""
