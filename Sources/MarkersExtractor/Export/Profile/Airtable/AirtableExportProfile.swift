//
//  AirtableExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct AirtableExportProfile: ExportProfile {
    public typealias Payload = CSVJSONExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = StandardExportMarker
    
    public init() { }
}
