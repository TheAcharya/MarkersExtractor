//
//  AirtableExportProfile Payload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct CSVExportPayload: ExportPayload {
    let csvPath: URL
        
    init(projectName: String, outputPath: URL) {
        let csvName = "\(projectName).csv"
        csvPath = outputPath.appendingPathComponent(csvName)
    }
}
