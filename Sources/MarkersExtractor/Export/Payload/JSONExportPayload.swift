//
//  JSONExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct JSONExportPayload: ExportPayload {
    let jsonPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let jsonName = "\(timelineName).json"
        jsonPath = outputURL.appendingPathComponent(jsonName)
    }
}
