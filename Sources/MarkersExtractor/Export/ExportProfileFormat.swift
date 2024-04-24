//
//  ExportProfileFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum ExportProfileFormat: String, CaseIterable, Equatable, Hashable {
    case airtable
    case csv
    case midi
    case notion
    case tsv
    case youtube
}

extension ExportProfileFormat {
    public var name: String {
        switch self {
        case .airtable:
            return "Airtable"
        case .csv:
            return "CSV"
        case .midi:
            return "MIDI File"
        case .notion:
            return "Notion"
        case .tsv:
            return "TSV"
        case .youtube:
            return "YouTube Chapters"
        }
    }
    
    public var concreteType: any ExportProfile.Type {
        switch self {
        case .airtable:
            return AirtableExportProfile.self
        case .csv:
            return CSVProfile.self
        case .midi:
            return MIDIFileExportProfile.self
        case .notion:
            return NotionExportProfile.self
        case .tsv:
            return TSVProfile.self
        case .youtube:
            return YouTubeProfile.self
        }
    }
}
