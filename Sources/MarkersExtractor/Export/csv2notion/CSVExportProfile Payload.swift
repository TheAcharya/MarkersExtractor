//
//  CSVExportProfile Payload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension CSVExportProfile {
    public struct Payload: ExportPayload {
        let csvPath: URL
    }
}
