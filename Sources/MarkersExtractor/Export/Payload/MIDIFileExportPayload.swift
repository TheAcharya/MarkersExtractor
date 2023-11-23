//
//  MIDIFileExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKit

public struct MIDIFileExportPayload: ExportPayload {
    let midiFilePath: URL
    let sessionStartTimecode: Timecode
    
    init(
        projectName: String,
        outputURL: URL,
        sessionStartTimecode: Timecode
    ) {
        let midiFileName = "\(projectName).mid"
        midiFilePath = outputURL.appendingPathComponent(midiFileName)
        
        self.sessionStartTimecode = sessionStartTimecode
    }
}
