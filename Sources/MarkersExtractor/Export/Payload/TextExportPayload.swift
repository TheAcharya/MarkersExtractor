//
//  TextExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct TextExportPayload: ExportPayload {
    let txtPath: URL
        
    init(projectName: String, outputURL: URL) {
        let txtName = "\(projectName).txt"
        txtPath = outputURL.appendingPathComponent(txtName)
    }
}
