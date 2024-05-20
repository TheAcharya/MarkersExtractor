//
//  CSVJSONExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct CSVJSONExportPayload: ExportPayload {
    let csvPayload: CSVExportPayload
    let jsonPayload: JSONExportPayload
    
    init(timelineName: String, outputURL: URL) {
        csvPayload = .init(timelineName: timelineName, outputURL: outputURL)
        jsonPayload = .init(timelineName: timelineName, outputURL: outputURL)
    }
}
