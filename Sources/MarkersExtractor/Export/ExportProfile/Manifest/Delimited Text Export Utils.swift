//
//  Delimited Text Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TextFileKit

extension ExportProfile {
    func dictsToRows(
        _ preparedMarkers: [PreparedMarker],
        includeHeader: Bool,
        noMedia: Bool
    ) -> StringTable {
        let dicts = preparedMarkers.map {
            tableManifestFields(for: $0, noMedia: noMedia)
        }
        guard !dicts.isEmpty else { return [] }
        
        // header
        var result: StringTable = []
        
        if includeHeader {
            result.append(Array(dicts[0].keys.map { $0.name }))
        }
        
        // marker rows
        result += dicts.map { row in
            Array(row.values)
        }
        
        return result
    }
}
