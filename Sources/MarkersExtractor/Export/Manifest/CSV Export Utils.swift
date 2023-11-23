//
//  CSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CodableCSV
import Foundation
import OrderedCollections

extension ExportProfile {
    func csvWriteManifest(
        csvPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = csvDictsToRows(preparedMarkers, noMedia: noMedia)
        let csvData = try CSVWriter.encode(rows: rows, into: Data.self)
        try csvData.write(to: csvPath)
    }
    
    // MARK: Helpers
    
    private func csvDictsToRows(
        _ preparedMarkers: [PreparedMarker],
        noMedia: Bool
    ) -> [[String]] {
        let dicts = preparedMarkers.map { manifestFields(for: $0, noMedia: noMedia) }
        guard !dicts.isEmpty else { return [] }
        
        // header
        var result = [Array(dicts[0].keys.map { $0.name })]
        
        // marker rows
        result += dicts.map { row in
            Array(row.values)
        }
        
        return result
    }
}
