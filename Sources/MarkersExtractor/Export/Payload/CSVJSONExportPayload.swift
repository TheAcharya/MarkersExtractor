//
//  CSVExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct CSVJSONExportPayload: ExportPayload {
    let csvPayload: CSVExportPayload
    let jsonPayload: JSONExportPayload
    
    init(projectName: String, outputURL: URL) {
        csvPayload = .init(projectName: projectName, outputURL: outputURL)
        jsonPayload = .init(projectName: projectName, outputURL: outputURL)
    }
}
