//
//  TSVExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct TSVExportPayload: ExportPayload {
    let tsvPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let tsvName = "\(timelineName).tsv"
        tsvPath = outputURL.appendingPathComponent(tsvName)
    }
}
