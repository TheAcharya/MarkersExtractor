//
//  ProgressTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@testable import MarkersExtractor
import TimecodeKit
import XCTest

final class ProgressTests: XCTestCase {
    func testFCPXMLMarkerExtractor() async throws {
        var file = FCPXMLFile(fileContents: fcpxmlTestString)
        let extractor = try FCPXMLMarkerExtractor(
            fcpxml: &file,
            idNamingMode: .timelineNameAndTimecode,
            enableSubframes: false, 
            markersSource: .markers, 
            excludeRoles: [], 
            includeDisabled: true,
            logger: nil
        )
        
        XCTAssertEqual(extractor.progress.fractionCompleted, 0.0)
        let context = try XCTUnwrap(extractor.extractTimelineContext(defaultTimelineName: "Timeline"))
        _ = await extractor.extractMarkers(context: context)
        
        // NOTE: this may randomly fail because NSProgress is garbage
        XCTAssert(extractor.progress.fractionCompleted == 1.0 || extractor.progress.isFinished)
    }
    
    func testAnimatedImageExtractor() async throws {
        let videoData = try TestResource.videoTrack_29_97_Start_00_00_00_00.data()
        let videoPlaceholder = try TemporaryMediaFile(withData: videoData)
        let range = tc("00:00:00:00", at: .fps24) ... tc("00:00:00:10", at: .fps24)
        let descriptors: [ImageDescriptor] = range.map {
            ImageDescriptor(
                absoluteTimecode: $0,
                offsetFromVideoStart: $0,
                filename: UUID().uuidString,
                label: nil
            )
        }
        let outputFolder = FileManager.default.temporaryDirectory
        let outputFile = outputFolder.appendingPathComponent(UUID().uuidString + ".gif")
        
        // MARK: - AnimatedImagesWriter
        
        let writer = AnimatedImagesWriter(
            descriptors: descriptors,
            sourceMediaFile: videoPlaceholder.url,
            outputFolder: outputFolder,
            gifFPS: 29.97,
            gifSpan: 0.25,
            gifDimensions: nil,
            imageFormat: .gif,
            imageLabelProperties: .default()
        )
        
        XCTAssertEqual(writer.progress.fractionCompleted, 0.0)
        try await writer.write()
        
        // NOTE: this may randomly fail because NSProgress is garbage
        XCTAssert(writer.progress.fractionCompleted == 1.0 || writer.progress.isFinished)
        
        // MARK: - AnimatedImageExtractor
        
        let extractor = try AnimatedImageExtractor(
            AnimatedImageExtractor.ConversionSettings(
                timecodeRange: range,
                sourceMediaFile: videoPlaceholder.url,
                outputFile: outputFile,
                dimensions: nil,
                outputFPS: 29.97,
                imageFilter: nil,
                imageFormat: .gif
            )
        )
        
        XCTAssertEqual(extractor.progress.fractionCompleted, 0.0)
        let _ = try await extractor.convert()
        
        // NOTE: this may randomly fail because NSProgress is garbage
        XCTAssert(extractor.progress.fractionCompleted == 1.0 || extractor.progress.isFinished)
    }
    
    func testStillImageBatchExtractor() async throws {
        let videoData = try TestResource.videoTrack_29_97_Start_00_00_00_00.data()
        let videoPlaceholder = try TemporaryMediaFile(withData: videoData)
        let range = tc("00:00:00:00", at: .fps24) ... tc("00:00:00:10", at: .fps24)
        let descriptors: [ImageDescriptor] = range.map {
            ImageDescriptor(
                absoluteTimecode: $0,
                offsetFromVideoStart: $0,
                filename: UUID().uuidString,
                label: nil
            )
        }
        let outputFolder = FileManager.default.temporaryDirectory
        
        // ImagesWriter
        
        let writer = ImagesWriter(
            descriptors: descriptors,
            sourceMediaFile: videoPlaceholder.url,
            outputFolder: outputFolder,
            imageFormat: .png,
            imageJPGQuality: Double(MarkersExtractor.Settings.Defaults.imageQuality) / 100,
            imageDimensions: nil,
            imageLabelProperties: .default()
        )
        
        XCTAssertEqual(writer.progress.fractionCompleted, 0.0)
        try await writer.write()
        
        // NOTE: this may randomly fail because NSProgress is garbage
        XCTAssert(writer.progress.fractionCompleted == 1.0 || writer.progress.isFinished)
        
        // MARK: - StillImageBatchExtractor
        
        let extractor = StillImageBatchExtractor(
            StillImageBatchExtractor.ConversionSettings(
                descriptors: descriptors,
                sourceMediaFile: videoPlaceholder.url,
                outputFolder: outputFolder,
                frameFormat: .png,
                jpgQuality: nil,
                dimensions: nil,
                imageFilter: nil
            )
        )
        
        XCTAssertEqual(extractor.progress.fractionCompleted, 0.0)
        let _ = try await extractor.convert()
        
        // NOTE: this may randomly fail because NSProgress is garbage
        XCTAssert(extractor.progress.fractionCompleted == 1.0 || extractor.progress.isFinished)
    }
}

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
