//
//  ExportProfileFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Supported MarkersExtractor export profiles.
public enum ExportProfileFormat: String {
    case airtable
    case csv
    case json
    case midi
    case notion
    case tsv
    case xlsx
    case youtube
    case compressor
    case markdown
}

extension ExportProfileFormat: Equatable { }

extension ExportProfileFormat: Hashable { }

extension ExportProfileFormat: CaseIterable { }

extension ExportProfileFormat: Identifiable {
    public var id: Self { self }
}

extension ExportProfileFormat: Sendable { }

// MARK: - Properties

extension ExportProfileFormat {
    public var name: String {
        switch self {
        case .airtable:
            return "Airtable"
        case .csv:
            return "CSV"
        case .json:
            return "JSON"
        case .midi:
            return "MIDI File"
        case .notion:
            return "Notion"
        case .tsv:
            return "TSV"
        case .xlsx:
            return "Excel (XLSX)"
        case .youtube:
            return "YouTube Chapters"
        case .compressor:
            return "Compressor Chapters"
        case .markdown:
            return "Markdown"
        }
    }
    
    public var concreteType: any ExportProfile.Type {
        switch self {
        case .airtable:
            return AirtableExportProfile.self
        case .csv:
            return CSVProfile.self
        case .json:
            return JSONProfile.self
        case .midi:
            return MIDIFileExportProfile.self
        case .notion:
            return NotionExportProfile.self
        case .tsv:
            return TSVProfile.self
        case .xlsx:
            return ExcelProfile.self
        case .youtube:
            return YouTubeProfile.self
        case .compressor:
            return CompressorProfile.self
        case .markdown:
            return MarkdownProfile.self
        }
    }
}
