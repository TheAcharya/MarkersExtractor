//
//  AirtableExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum AirtableExportProfile: ExportProfile {
    public typealias Payload = CSVExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias Field = StandardExportField
    public typealias PreparedMarker = StandardExportMarker
}
