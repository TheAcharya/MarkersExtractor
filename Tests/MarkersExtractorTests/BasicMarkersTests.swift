import XCTest
@testable import MarkersExtractor
import TimecodeKit

final class BasicMarkersTests: XCTestCase {
    /// Basic test to check `MarkersExtractor.extractMarkers()` parses data correctly.
    func testBasicMarkers_extractMarkers() throws {
        let settings = try MarkersExtractor.Settings(
            fcpxml: .init(.fileContents(fcpxmlBasicMarkersData)),
            outputDir: FileManager.default.temporaryDirectory
        )
        let extractor = MarkersExtractor(settings)
        
        // verify marker contents
        
        let markers = try extractor.extractMarkers()
        
        XCTAssertEqual(markers.count, 4)
        
        let fr: TimecodeFrameRate = ._29_97
        
        let parentInfo = Marker.ParentInfo(
            clipName: "Basic Title",
            clipDuration: try TCC(h: 00, m: 01, s: 03, f: 29).toTimecode(at: fr),
            eventName: "Test Event",
            projectName: "Test Project",
            libraryName: "MyLibrary.fcpbundle"
        )
        
        let marker0 = markers[0]
        XCTAssertEqual(marker0.type, .standard)
        XCTAssertEqual(marker0.name, "Standard Marker")
        XCTAssertEqual(marker0.notes, "some notes here")
        XCTAssertEqual(marker0.role, "Titles")
        XCTAssertEqual(marker0.position, try TCC(h: 00, m: 00, s: 29, f: 14).toTimecode(at: fr))
        XCTAssertEqual(marker0.parentInfo, parentInfo)
        
        let marker1 = markers[1]
        XCTAssertEqual(marker1.type, .todo(completed: false))
        XCTAssertEqual(marker1.name, "To Do Marker, Incomplete")
        XCTAssertEqual(marker1.notes, "more notes here")
        XCTAssertEqual(marker1.role, "Titles")
        XCTAssertEqual(marker1.position, try TCC(h: 00, m: 00, s: 29, f: 15).toTimecode(at: fr))
        XCTAssertEqual(marker1.parentInfo, parentInfo)
        
        let marker2 = markers[2]
        XCTAssertEqual(marker2.type, .todo(completed: true))
        XCTAssertEqual(marker2.name, "To Do Marker, Completed")
        XCTAssertEqual(marker2.notes, "notes yay")
        XCTAssertEqual(marker2.role, "Titles")
        XCTAssertEqual(marker2.position, try TCC(h: 00, m: 00, s: 29, f: 16).toTimecode(at: fr))
        XCTAssertEqual(marker2.parentInfo, parentInfo)
        
        let marker3 = markers[3]
        XCTAssertEqual(marker3.type, .chapter)
        XCTAssertEqual(marker3.name, "Chapter Marker")
        XCTAssertEqual(marker3.notes, "")
        XCTAssertEqual(marker3.role, "Titles")
        XCTAssertEqual(marker3.position, try TCC(h: 00, m: 00, s: 29, f: 17).toTimecode(at: fr))
        XCTAssertEqual(marker3.parentInfo, parentInfo)
    }
}

fileprivate let fcpxmlBasicMarkersData = fcpxmlBasicMarkers.data(using: .utf8)!
fileprivate let fcpxmlBasicMarkers = """
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
                            <marker start="27248221/7500s" duration="1001/30000s" value="Standard Marker" note="some notes here"/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="To Do Marker, Incomplete" completed="0" note="more notes here"/>
                            <marker start="54497443/15000s" duration="1001/30000s" value="To Do Marker, Completed" completed="1" note="notes yay"/>
                            <chapter-marker start="108995887/30000s" duration="1001/30000s" value="Chapter Marker" posterOffset="11/30s"/>
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
