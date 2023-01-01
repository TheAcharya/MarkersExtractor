//
//  CSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import CodableCSV

extension ExportProfile {
    static func csvWiteManifest(
        csvPath: URL,
        _ preparedMarkers: [PreparedMarker],
        payload: Payload
    ) throws {
        let rows = csvDictsToRows(preparedMarkers)
        let csvData = try CSVWriter.encode(rows: rows, into: Data.self)
        try csvData.write(to: csvPath)
    }
    
    public static func csvDoneFileContent(csvPath: URL) throws -> Data {
        let content = ["csvPath": csvPath.path]
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        return try encoder.encode(content)
    }
    
    // MARK: Helpers
    
    private static func csvDictsToRows(
        _ preparedMarkers: [PreparedMarker]
    ) -> [[String]] {
        let dicts = preparedMarkers.map { manifestFields(for: $0) }
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
