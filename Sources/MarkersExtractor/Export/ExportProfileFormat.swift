//
//  ExportProfileFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum ExportProfileFormat: String, CaseIterable {
    case airtable
    case notion
}

extension ExportProfileFormat {
    var name: String {
        switch self {
        case .airtable:
            return "Airtable"
        case .notion:
            return "Notion (csv2notion)"
        }
    }
}
