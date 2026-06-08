//
//  MIDIFileExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import SwiftTimecodeCore

public struct MIDIFileExportPayload: ExportPayload {
    let midiFilePath: URL
    let timelineStartTimecode: Timecode
    let isUTF8TextEncodingAllowed: Bool
    
    init(
        timelineName: String,
        outputURL: URL,
        timelineStartTimecode: Timecode,
        isUTF8TextEncodingAllowed: Bool
    ) {
        let midiFileName = "\(timelineName).mid"
        midiFilePath = outputURL.appendingPathComponent(midiFileName)

        self.timelineStartTimecode = timelineStartTimecode
        self.isUTF8TextEncodingAllowed = isUTF8TextEncodingAllowed
    }
}

extension MIDIFileExportPayload: Sendable { }
