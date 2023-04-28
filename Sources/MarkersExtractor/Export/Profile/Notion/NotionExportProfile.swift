//
//  NotionExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct NotionExportProfile: ExportProfile {
    public typealias Payload = CSVExportPayload
    public typealias PreparedMarker = StandardExportMarker
    
    public init() { }
}
