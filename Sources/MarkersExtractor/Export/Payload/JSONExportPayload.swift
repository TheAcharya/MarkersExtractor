//
//  JSONExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct JSONExportPayload: ExportPayload {
    let jsonPath: URL
        
    init(projectName: String, outputURL: URL) {
        let jsonName = "\(projectName).json"
        jsonPath = outputURL.appendingPathComponent(jsonName)
    }
}
