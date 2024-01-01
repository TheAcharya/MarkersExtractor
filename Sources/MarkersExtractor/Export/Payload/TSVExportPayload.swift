//
//  TSVExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct TSVExportPayload: ExportPayload {
    let tsvPath: URL
        
    init(projectName: String, outputURL: URL) {
        let tsvName = "\(projectName).tsv"
        tsvPath = outputURL.appendingPathComponent(tsvName)
    }
}
