//
//  SRTExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct SRTExportPayload: ExportPayload {
    let srtPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let srtName = "\(timelineName).srt"
        srtPath = outputURL.appendingPathComponent(srtName)
    }
}

extension SRTExportPayload: Sendable { }
