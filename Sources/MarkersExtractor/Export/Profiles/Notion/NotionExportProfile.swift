//
//  NotionExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum NotionExportProfile: ExportProfile {
    public typealias Payload = CSVExportPayload
    public typealias Field = StandardExportField
    public typealias PreparedMarker = StandardExportMarker
}
