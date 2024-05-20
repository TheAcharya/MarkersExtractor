//
//  MIDIFileExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKit

public struct MIDIFileExportPayload: ExportPayload {
    let midiFilePath: URL
    let timelineStartTimecode: Timecode
    
    init(
        timelineName: String,
        outputURL: URL,
        timelineStartTimecode: Timecode
    ) {
        let midiFileName = "\(timelineName).mid"
        midiFilePath = outputURL.appendingPathComponent(midiFileName)
        
        self.timelineStartTimecode = timelineStartTimecode
    }
}
