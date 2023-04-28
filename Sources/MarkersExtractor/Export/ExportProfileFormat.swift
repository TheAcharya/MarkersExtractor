//
//  ExportProfileFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum ExportProfileFormat: String, CaseIterable {
    case airtable
    case midi
    case notion
}

extension ExportProfileFormat {
    public var name: String {
        switch self {
        case .airtable:
            return "Airtable"
        case .midi:
            return "MIDI File"
        case .notion:
            return "Notion (csv2notion)"
        }
    }
    
    public var concreteType: any ExportProfile.Type {
        switch self {
        case .airtable:
            return AirtableExportProfile.self
        case .midi:
            return MIDIFileExportProfile.self
        case .notion:
            return NotionExportProfile.self
        }
    }
}
