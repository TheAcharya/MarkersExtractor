//
//  MarkersExtractorTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import XCTest
@testable import MarkersExtractor
import TimecodeKit

final class MarkersExtractorTests: XCTestCase {
    func testFindDuplicateIDs_inMarkers() throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(.fileContents("")),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .projectTimecode
        
        let extractor = MarkersExtractor(settings)
        
        func makeMarker(_ name: String, position: TCC) -> Marker {
            Marker(
                type: .standard,
                name: name,
                notes: "",
                roles: [.video("Video")],
                position: try! position.toTimecode(at: ._24),
                parentInfo: .init(
                    clipName: "Some Clip",
                    clipDuration: try! TCC(h: 1).toTimecode(at: ._24),
                    eventName: "Some Event",
                    projectName: "MyProject",
                    libraryName: "MyLibrary"
                )
            )
        }
        
        let marker1 = makeMarker("marker1", position: TCC(f: 1))
        let marker2 = makeMarker("marker2", position: TCC(f: 2))
        
        XCTAssertEqual(
            extractor.findDuplicateIDs(in: []), []
        )
        
        XCTAssertEqual(
            extractor.findDuplicateIDs(in: [marker1]), []
        )
        
        XCTAssertEqual(
            extractor.findDuplicateIDs(in: [marker1, marker2]), []
        )
        
        XCTAssertEqual(
            extractor.findDuplicateIDs(in: [marker1, marker1]), [marker1.id(settings.idNamingMode)]
        )
        
        XCTAssertEqual(
            extractor.findDuplicateIDs(in: [marker2, marker1, marker2]),
            [marker2.id(settings.idNamingMode)]
        )
    }
    
    func testIsAllUniqueIDNonEmpty_inMarkers() throws {
        var settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(.fileContents("")),
            outputDir: FileManager.default.temporaryDirectory
        )
        settings.idNamingMode = .name
        
        let extractor = MarkersExtractor(settings)
        
        func makeMarker(_ name: String, position: TCC) -> Marker {
            Marker(
                type: .standard,
                name: name,
                notes: "",
                roles: [.video("Video")],
                position: try! position.toTimecode(at: ._24),
                parentInfo: .init(
                    clipName: "Some Clip",
                    clipDuration: try! TCC(h: 1).toTimecode(at: ._24),
                    eventName: "Some Event",
                    projectName: "MyProject",
                    libraryName: "MyLibrary"
                )
            )
        }
        
        let marker1 = makeMarker("marker1", position: TCC(f: 1))
        let marker2 = makeMarker("", position: TCC(f: 2))
        
        XCTAssertTrue(
            extractor.isAllUniqueIDNonEmpty(in: [])
        )
        
        XCTAssertTrue(
            extractor.isAllUniqueIDNonEmpty(in: [marker1])
        )
        
        XCTAssertFalse(
            extractor.isAllUniqueIDNonEmpty(in: [marker1, marker2])
        )
        
        XCTAssertFalse(
            extractor.isAllUniqueIDNonEmpty(in: [marker2])
        )
    }
}
