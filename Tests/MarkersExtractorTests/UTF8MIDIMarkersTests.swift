//
//  UTF8MIDIMarkersTests.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation
@testable import MarkersExtractor
import SwiftMIDIFile
import SwiftTimecodeCore
import Testing
import TestingExtensions

@Suite
struct UTF8MIDIMarkersTests {
    /// Test allowing UTF-8 text encoding when exporting MIDI files.
    @Test
    func exportMIDIFile_allowUTF8() async throws {
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory,
            exportFormat: .midi,
            isMIDIFileUTF8EncodingAllowed: true
        )

        let extractor = MarkersExtractor(settings: settings)

        let result = try await extractor.extract()

        let filePath = try #require(result.midiFilePath)

        let midiFile = try await MusicalMIDI1File(url: filePath)

        // verify marker text strings

        #expect(midiFile.tracks.count == 1)
        let track = try #require(midiFile.tracks.first)

        let textEvents: [MIDIFileEvent.Text] = track.events
            .map(\.event)
            .compactMap {
                guard case let .text(text) = $0 else { return nil }
                return text
            }

        try #require(textEvents.count == 1 + 4) // track name + 4 marker events

        #expect(textEvents[0].text == "Markers")
        #expect(textEvents[0].textType == .trackOrSequenceName)

        #expect(textEvents[1].text == "Marker 1 is ASCII")
        #expect(textEvents[1].textType == .marker)

        #expect(textEvents[2].text == "Marker 2 © is Extended ASCII")
        #expect(textEvents[2].textType == .marker)

        #expect(textEvents[3].text == "Marker 3 😀 is UTF-8")
        #expect(textEvents[3].textType == .marker)

        #expect(textEvents[4].text == "请请让我知道")
        #expect(textEvents[4].textType == .marker)
    }

    /// Test NOT allowing UTF-8 text encoding (enforcing printable ASCII) when exporting MIDI files.
    @Test
    func exportMIDIFile_doNotAllowUTF8() async throws {
        let settings = try MarkersExtractor.Settings(
            fcpxml: FCPXMLFile(fileContents: fcpxmlTestData),
            outputDir: FileManager.default.temporaryDirectory,
            exportFormat: .midi,
            isMIDIFileUTF8EncodingAllowed: false
        )

        let extractor = MarkersExtractor(settings: settings)

        let result = try await extractor.extract()

        let filePath = try #require(result.midiFilePath)

        let midiFile = try await MusicalMIDI1File(url: filePath)

        // verify marker text strings

        #expect(midiFile.tracks.count == 1)
        let track = try #require(midiFile.tracks.first)

        let textEvents: [MIDIFileEvent.Text] = track.events
            .map(\.event)
            .compactMap {
                guard case let .text(text) = $0 else { return nil }
                return text
            }

        try #require(textEvents.count == 1 + 4) // track name + 4 marker events

        #expect(textEvents[0].text == "Markers")
        #expect(textEvents[0].textType == .trackOrSequenceName)

        #expect(textEvents[1].text == "Marker 1 is ASCII")
        #expect(textEvents[1].textType == .marker)

        #expect(textEvents[2].text == "Marker 2 (C) is Extended ASCII") // substitutes non-ASCII char
        #expect(textEvents[2].textType == .marker)

        #expect(textEvents[3].text == "Marker 3 ? is UTF-8") // can't substitute non-ASCII char, uses `?` placeholder
        #expect(textEvents[3].textType == .marker)

        #expect(textEvents[4].text == "??????") // can't substitute non-ASCII chars, uses `?` placeholders
        #expect(textEvents[4].textType == .marker)
    }
}

// swiftformat:disable indent

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
                            <marker start="27248221/7500s" duration="1001/30000s" value="Marker 1 is ASCII" note="some notes here"/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="Marker 2 © is Extended ASCII" completed="0" note="more notes here"/>
                            <marker start="7266259/2000s" duration="1001/30000s" value="Marker 3 😀 is UTF-8" completed="1" note="notes yay"/>
                            <chapter-marker start="108995887/30000s" duration="1001/30000s" value="请请让我知道" posterOffset="11/30s" note="more notes here"/>
                        </title>
                    </spine>
                </sequence>
            </project>
        </event>
    </library>
</fcpxml>
"""
