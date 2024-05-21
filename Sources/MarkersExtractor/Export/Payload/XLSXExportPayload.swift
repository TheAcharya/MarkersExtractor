//
//  XLSXExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct XLSXExportPayload: ExportPayload {
    let xlsxPath: URL
        
    init(timelineName: String, outputURL: URL) {
        let csvName = "\(timelineName).xlsx"
        xlsxPath = outputURL.appendingPathComponent(csvName)
    }
}
