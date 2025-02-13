//
//  CSVExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct CSVExportPayload: ExportPayload {
    let csvPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let csvName = "\(timelineName).csv"
        csvPath = outputURL.appendingPathComponent(csvName)
    }
}

extension CSVExportPayload: Sendable { }
