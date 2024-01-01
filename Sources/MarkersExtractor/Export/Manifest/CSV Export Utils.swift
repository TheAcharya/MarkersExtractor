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
        let rows = dictsToRows(preparedMarkers, noMedia: noMedia)
        let csvData = try CSVWriter.encode(rows: rows, into: Data.self)
        try csvData.write(to: csvPath)
    }
}
