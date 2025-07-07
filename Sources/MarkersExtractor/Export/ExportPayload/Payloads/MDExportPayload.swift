//
//  MDExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct MDExportPayload: ExportPayload {
    let mdPath: URL
    let title: String
    
    init(timelineName: String, outputURL: URL) {
        let mdName = "\(timelineName).md"
        mdPath = outputURL.appendingPathComponent(mdName)
        
        title = timelineName
    }
}

extension MDExportPayload: Sendable { }
