//
//  ExportProfileFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Supported MarkersExtractor export profiles.
public enum ExportProfileFormat: String {
    case airtable
    case compressor
    case csv
    case json
    case midi
    case notion
    case tsv
    case xlsx
    case youtube
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
        case .airtable: "Airtable"
        case .compressor: "Compressor Chapters"
        case .csv: "CSV"
        case .json: "JSON"
        case .midi: "MIDI File"
        case .notion: "Notion"
        case .tsv: "TSV"
        case .xlsx: "Excel (XLSX)"
        case .youtube: "YouTube Chapters"
        }
    }
    
    public var concreteType: any ExportProfile.Type {
        switch self {
        case .airtable: AirtableExportProfile.self
        case .compressor: CompressorProfile.self
        case .csv: CSVProfile.self
        case .json: JSONProfile.self
        case .midi: MIDIFileExportProfile.self
        case .notion: NotionExportProfile.self
        case .tsv: TSVProfile.self
        case .xlsx: ExcelProfile.self
        case .youtube: YouTubeProfile.self
        }
    }
}
