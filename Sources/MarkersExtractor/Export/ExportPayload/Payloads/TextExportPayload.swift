//
//  TextExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct TextExportPayload: ExportPayload {
    let txtPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let txtName = "\(timelineName).txt"
        txtPath = outputURL.appendingPathComponent(txtName)
    }
}

extension TextExportPayload: Sendable { }
