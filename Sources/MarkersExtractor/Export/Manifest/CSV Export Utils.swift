//
//  CSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TextFileKit

extension ExportProfile {
    func csvWriteManifest(
        csvPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = dictsToRows(preparedMarkers, noMedia: noMedia)
        
        guard let csvData = TextFile.CSV(table: rows).rawText.data(using: .utf8)
        else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode CSV file."
            ))
        }
        
        try csvData.write(to: csvPath)
    }
}
